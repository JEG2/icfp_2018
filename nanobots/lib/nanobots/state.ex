defmodule Nanobots.State do
  alias Nanobots.{Bot, Coord, Model, Trace}
  alias Nanobots.Commands.{
    Halt, Wait, Flip, SMove, LMove, Fill, GFill, Void, GVoid,
    Fission, FusionP, FusionS
  }

  defstruct energy: 0,
            harmonics: :low,
            matrix: nil,
            model: nil,
            bots: [%Bot{bid: 1, pos: {0, 0, 0}, seeds: Enum.to_list(2..40)}],
            trace: nil,
            problem: nil

  @nds ( for x <- -1..1, y <- -1..1, z <- -1..1,
             abs(x) + abs(y) + abs(z) in [1, 2] do
           {x, y, z}
         end )

  def from_model(path) do
    {model, matrix, problem} =
      case path |> Path.basename |> String.slice(0..1) do
        "FA" ->
          target = Model.from_file(path)
          empty = %Model{target | matrix: MapSet.new}
          {target, empty, :assemble}
        "FD" ->
          src = Model.from_file(path)
          empty = %Model{src | matrix: MapSet.new}
          {empty, src, :disassemble}
        "FR" ->
          {src_path, tgt_path} =
            if String.contains?(path, "_src") do
              {path, String.replace(path, "_src", "_tgt")}
            else
              {String.replace(path, "_tgt", "_src"), path}
            end
          src = Model.from_file(src_path)
          tgt = Model.from_file(tgt_path)
          {tgt, src, :reassemble}
      end
    trace =
      path
      |> String.replace(~r{\.mdl\z}, ".nbt")
      |> Trace.new
    %__MODULE__{matrix: matrix, model: model, trace: trace, problem: problem}
  end

  def apply(state, commands) do
    validate_commands(state, commands)

    new_state =
      state.bots
      |> Enum.zip(commands)
      |> Enum.reduce(state, fn {bot, command}, s ->
        apply_command(s, bot, command)
      end)

    Trace.record_timestep(state.trace, commands)

    if end?(new_state) do
      Trace.close(state.trace)
    end
    %{
      new_state |
      energy: new_state.energy + calculate_harmonics_energy(state)
    }
  end

  def validate_commands(state, commands) do
    length(state.bots) == length(commands) || raise "Wrong number of commands"

    Enum.count(commands, fn %Flip{ } -> true; _command -> false end) > 1 &&
      raise "Multiple flips"

    bots_with_commands = Enum.zip(state.bots, commands)
    fusion_ps = Enum.filter(
      bots_with_commands,
      fn {_p_bot, %FusionP{ }} -> true; _command -> false end
    )
    Enum.all?(fusion_ps, fn {p_bot, %FusionP{nd: p_nd}} ->
      s_pos = Coord.calculate_cprime(p_bot.pos, p_nd)
      Enum.count(bots_with_commands, fn {s_bot, %FusionS{nd: s_nd}} ->
        s_bot.pos == s_pos &&
          Coord.calculate_cprime(s_bot.pos, s_nd) == p_bot.pos
      end) == 1
    end) ||
      raise "Mismatched fusion"

    validate_gfill_commands(state, commands)
    validate_gvoid_commands(state, commands)
  end

  def apply_command(
    %__MODULE__{
      harmonics: :low,
      bots: [%Bot{pos: {0, 0, 0}} = bot]
    } = state,
    bot,
    %Halt{ }
  ) do
    %__MODULE__{state | bots: [ ]}
  end
  def apply_command(state, _bot, %Wait{ }) do
    state
  end
  def apply_command(%__MODULE__{harmonics: :low} = state, _bot, %Flip{ }) do
    %__MODULE__{state | harmonics: :high}
  end
  def apply_command(%__MODULE__{harmonics: :high} = state, _bot, %Flip{ }) do
    %__MODULE__{state | harmonics: :low}
  end
  def apply_command(state, bot, %SMove{lld: lld}) do
    %__MODULE__{
      state |
      bots: replace_bot(
        state.bots,
        %Bot{bot | pos: Coord.calculate_cprime(bot.pos, lld)}
      ),
      energy: state.energy + 2 * Coord.mlen(lld)
    }
  end
  def apply_command(state, bot, %LMove{sld1: sld1, sld2: sld2}) do
    final_pos =
      bot.pos
      |> Coord.calculate_cprime(sld1)
      |> Coord.calculate_cprime(sld2)
    %__MODULE__{
      state |
      bots: replace_bot(state.bots, %Bot{bot | pos: final_pos}),
      energy: state.energy + 2 * (Coord.mlen(sld1) + 2 + Coord.mlen(sld2))
    }
  end
  def apply_command(state, bot, %Fill{nd: nd}) when nd in @nds do
    filled = Coord.calculate_cprime(bot.pos, nd)

    if Model.filled?(state.matrix, filled) do
      raise "Already filled"
    end

    %__MODULE__{
      state |
      matrix: Model.fill(state.matrix, filled),
      energy: state.energy + 12
    }
  end
  def apply_command(state, bot, %GFill{nd: nd, fd: fd}) when nd in @nds do
    filled = Coord.garea(bot.pos, nd, fd)
    energy = Enum.reduce(filled, state.energy, fn(voxel, total) ->
      if Model.filled?(state.matrix, voxel) do
        total + 6
      else
        total + 12
      end
    end)
    %__MODULE__{
      state |
      matrix: Model.fill(state.matrix, filled),
      energy: energy
    }
  end
  def apply_command(state, bot, %Void{nd: nd}) when nd in @nds do
    voided = Coord.calculate_cprime(bot.pos, nd)

    if !Model.filled?(state.matrix, voided) do
      raise "Already void"
    end

    %__MODULE__{
      state |
      matrix: Model.void(state.matrix, voided),
      energy: state.energy - 12
    }
  end
  def apply_command(state, bot, %GVoid{nd: nd, fd: fd}) when nd in @nds do
    filled = Coord.garea(bot.pos, nd, fd)
    energy = Enum.reduce(filled, state.energy, fn(voxel, total) ->
      if Model.filled?(state.matrix, voxel) do
        total - 12
      else
        total + 3
      end
    end)
    %__MODULE__{
      state |
      matrix: Model.void(state.matrix, filled),
      energy: energy
    }
  end
  def apply_command(state, bot, %Fission{nd: nd, m: m}) when nd in @nds do
    new_bot_position = Coord.calculate_cprime(bot.pos, nd)
    [new_bot_id | new_bot_seeds] = Enum.take(bot.seeds, m + 1)
    new_bot = %Bot{
      bid: new_bot_id,
      pos: new_bot_position,
      seeds: new_bot_seeds
    }
   %__MODULE__{
      state |
      bots:
        state.bots
        |> replace_bot(%Bot{bot | seeds: Enum.drop(bot.seeds, m + 1)})
        |> add_bot(new_bot),
      energy: state.energy + 24
    }
  end
  def apply_command(state, bot, %FusionP{nd: nd}) when nd in @nds do
    other_bot_position = Coord.calculate_cprime(bot.pos, nd)
    other_bot = Enum.find(
      state.bots,
      fn %Bot{pos: ^other_bot_position} -> true; _bot -> false end
    )
    %__MODULE__{
      state |
      bots:
        state.bots
        |> replace_bot(
          %Bot{
            bot |
            seeds: Enum.sort(bot.seeds ++ [other_bot.bid] ++ other_bot.seeds)
          }
        )
        |> remove_bot(other_bot),
      energy: state.energy - 24
    }
  end
  def apply_command(state, _bot, %FusionS{nd: nd}) when nd in @nds do
    state
  end

  def end?(%__MODULE__{bots: [ ]}), do: true
  def end?(_state), do: false

  defp replace_bot(bots, %Bot{bid: bid} = new_bot) do
    Enum.map(bots, fn %Bot{bid: ^bid} -> new_bot; bot -> bot end)
  end

  defp add_bot(bots, new_bot) do
    Enum.sort_by([new_bot | bots], fn %Bot{bid: bid} -> bid end)
  end

  defp remove_bot(bots, bot) do
    List.delete(bots, bot)
  end

  defp calculate_harmonics_energy(state = %__MODULE__{harmonics: :low}) do
    r = state.matrix.resolution
    3 * r * r * r
    |> add_robot_energy(state)
  end
  defp calculate_harmonics_energy(state = %__MODULE__{harmonics: :high}) do
    r = state.matrix.resolution
    30 * r * r * r
    |> add_robot_energy(state)
  end

  defp add_robot_energy(energy, state) do
    energy + 20 * length(state.bots)
  end

  defp validate_gfill_commands(state, commands) do
    state.bots
    |> Enum.zip(commands)
    |> Enum.filter(fn
      {_bot, %Nanobots.Commands.GFill{}} -> true
      _ -> false
    end)
    |> Enum.map(fn {bot, command} ->
      %{
        dimension: Coord.garea_dimensions(command.nd, command.fd),
        garea: MapSet.new(Coord.garea(bot.pos, command.nd, command.fd))
      }
    end)
    |> validate_g_commands
  end

  defp validate_gvoid_commands(state, commands) do
    state.bots
    |> Enum.zip(commands)
    |> Enum.filter(fn
      {_bot, %Nanobots.Commands.GVoid{}} -> true
      _ -> false
    end)
    |> Enum.map(fn {bot, command} ->
      %{
        dimension: Coord.garea_dimensions(command.nd, command.fd),
        garea: MapSet.new(Coord.garea(bot.pos, command.nd, command.fd))
      }
    end)
    |> validate_g_commands
  end

  defp validate_g_commands([]) do
    true
  end
  defp validate_g_commands([first | rest]) do
    expected_other_commands_length = :math.pow(2, first.dimension) - 1
    matching_other_commands = Enum.filter(rest, fn data ->
      MapSet.equal?(first.garea, data.garea)
    end)
    unless expected_other_commands_length == length(matching_other_commands) do
      raise "g command has invalid number of coordinated bots"
    end

    validate_g_commands(rest |> Enum.reject(fn data -> MapSet.equal?(first.garea, data.garea) end))
  end
end
