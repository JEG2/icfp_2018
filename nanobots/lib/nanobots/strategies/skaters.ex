defmodule Nanobots.Strategies.Skaters do
  alias Nanobots.{Coord, Model, Pathfinder}
  alias Nanobots.Commands.{Halt, Wait, Fission, GFill, FusionP, FusionS}

  @behaviour Nanobots.Strategy
  @max_fill 30

  def move(state, memory) when memory == %{} do
    unless state.problem == :assemble do
      raise "Problem type mismatch"
    end
    new_memory = memory
                 |> Map.put(:phase, :move_for_fill)
                 |> Map.put(:move_queue, [])
                 |> Map.put(:next_check, [find_start_of_next_line(state, {0,0,0})])
                 |> Map.put(:start_of_line, nil)
                 |> Map.put(:end_of_line, nil)
                 |> Map.put(:next_level_start, nil)
    {[%Fission{nd: {1,0,0}, m: 0}], new_memory}
  end
  def move(_state, memory = %{move_queue: move_queue}) when length(move_queue) > 0 do
    {Tuple.to_list(hd(move_queue)), %{memory | move_queue: tl(move_queue)}}
  end
  def move(state, memory = %{phase: :move_for_fill}) do
    miki_bot = List.first(state.bots)
    stephen_bot = List.last(state.bots)
    cleaned_next_check = clean_next_check(state, memory.next_check)
    if (cleaned_next_check == []) do
      move(state, %{memory | phase: :move_for_fill, next_check: [memory.next_level_start]})
    else
      [starting_point | next_check] = cleaned_next_check
      next_line = find_next_line(state, starting_point)
      next_check = generate_next_check_points(state, next_line, next_check)
      next_level_start = find_next_level_start(state, next_line)
      new_memory = if next_level_start do
                     %{memory | next_level_start: next_level_start}
                   else
                     memory
                   end
      start_of_line = List.last(next_line) # yes last
      end_of_line = List.first(next_line) # yes first
      miki_goal = find_near_destination(state, next_line, start_of_line)
      stephen_goal = find_near_destination(state, next_line, end_of_line)
      miki_bot_path = Pathfinder.path(miki_bot.pos, miki_goal, state.matrix, [])
      miki_bot_moves = Pathfinder.to_moves(miki_bot, miki_bot_path)
      stephen_bot_path = Pathfinder.path(stephen_bot.pos, stephen_goal, state.matrix, miki_bot_moves)
      stephen_bot_moves = Pathfinder.to_moves(stephen_bot, stephen_bot_path)
      {miki_bot_moves, stephen_bot_moves} = pad_with_waits(miki_bot_moves, stephen_bot_moves)
      [next_moves | queued_moves] = Enum.zip(miki_bot_moves, stephen_bot_moves)
      {Tuple.to_list(next_moves), %{new_memory |
        move_queue: queued_moves,
        phase: :fill,
        start_of_line: start_of_line,
        end_of_line: end_of_line,
        next_check: next_check
      }}
    end
  end
  def move(state, memory = %{phase: :fill}) do
    miki_bot = List.first(state.bots)
    miki_nd = Coord.difference(miki_bot.pos, memory.start_of_line)
    miki_fd = Coord.difference(memory.start_of_line, memory.end_of_line)

    stephen_bot = List.last(state.bots)
    stephen_nd = Coord.difference(stephen_bot.pos, memory.end_of_line)
    stephen_fd = Coord.difference(memory.end_of_line, memory.start_of_line)

    next_moves = [%GFill{nd: miki_nd, fd: miki_fd}, %GFill{nd: stephen_nd, fd: stephen_fd}]
    {next_moves, %{memory | phase: :check_for_done}}
  end
  def move(state, memory = %{phase: :check_for_done}) do
    if model_done?(state) do
      move(state, %{memory | phase: :prep_for_fusion})
    else
      move(state, %{memory | phase: :move_for_fill})
    end
  end
  def move(state, memory = %{phase: :prep_for_fusion}) do
    miki_bot = List.first(state.bots)
    stephen_bot = List.last(state.bots)
    miki_goal = {0,0,0}
    stephen_goal = {1,0,0}
    miki_bot_path = Pathfinder.path(miki_bot.pos, miki_goal, state.matrix, [])
    miki_bot_moves = Pathfinder.to_moves(miki_bot, miki_bot_path)
    stephen_bot_path = Pathfinder.path(stephen_bot.pos, stephen_goal, state.matrix, miki_bot_moves)
    stephen_bot_moves = Pathfinder.to_moves(stephen_bot, stephen_bot_path)
    if (miki_bot_moves == [] && stephen_bot_moves == []) do
      move(state, %{memory | phase: :fusion})
    else
      {miki_bot_moves, stephen_bot_moves} = pad_with_waits(miki_bot_moves, stephen_bot_moves)
      [next_moves | queued_moves] = Enum.zip(miki_bot_moves, stephen_bot_moves)
      {Tuple.to_list(next_moves), %{memory |
        move_queue: queued_moves,
        phase: :fusion
      }}
    end
  end
  def move(_state, memory = %{phase: :fusion}) do
    next_moves = [%FusionP{nd: {1,0,0}}, %FusionS{nd: {-1,0,0}}]
    {next_moves, %{memory | phase: :end}}
  end
  def move(_state, memory = %{phase: :end}) do
    {[%Halt{}], memory}
  end

  def pad_with_waits(m1, m2) when length(m1) == length(m2) do
    {m1, m2}
  end
  def pad_with_waits(m1, m2) when length(m1) > length(m2) do
    pad_with_waits(m1, [%Wait{} | m2])
  end
  def pad_with_waits(m1, m2) when length(m1) < length(m2) do
    pad_with_waits([%Wait{} | m1], m2)
  end

  def find_next_line(state, maybe_start_point) do
    well_actually_start_point = find_leftmost_possible_start_point(state, maybe_start_point)
    find_longest_possible_continuous_line(state, well_actually_start_point)
  end

  def find_start_of_next_line(state, {x, y, z}) do
    case Model.filled?(state.model, {x, y, z}) do
      true -> {x, y, z}
      false ->
        if (x == state.model.resolution) do
          x = 0
          find_start_of_next_line(state, {x, y, z+1})
        else
          find_start_of_next_line(state, {x+1, y, z})
        end
    end
  end

  def find_longest_possible_continuous_line(state, start) do
    find_longest_possible_continuous_line(state, start, [])
  end
  def find_longest_possible_continuous_line(_state, _point, line) when length(line) >= @max_fill do
    line
  end
  def find_longest_possible_continuous_line(state, point = {x,y,z}, line) do
    if x >= state.model.resolution do
      line
    end

    if needs_to_be_filled?(state, point) do
      find_longest_possible_continuous_line(state, {x+1, y, z}, [point | line])
    else
      line
    end
  end

  def needs_to_be_filled?(state, point) do
    Model.filled?(state.model, point) && !Model.filled?(state.matrix, point)
  end

  def possible_destination(state, _memory, point) do
    !Model.filled?(state.matrix, point)
  end

  def find_near_destination(state, line, point) do
    possible_destinations = Coord.near(point, state.model.resolution)
    possible_destinations
    |> Enum.reject(fn destination -> destination in line end)
    |> Enum.find(fn destination -> !Model.filled?(state.matrix, destination) end)
  end

  def model_done?(state) do
    MapSet.equal?(state.matrix.matrix, state.model.matrix)
  end

  def clean_next_check(state, points_to_check) do
    points_to_check
    |> Enum.filter(fn point -> needs_to_be_filled?(state, point) end)
  end

  def generate_next_check_points(state, next_line, next_check) do
    new_next_checks = next_line
    |> Enum.map(fn point -> surrounding_points(state, point) end)
    |> List.flatten
    next_check ++ Enum.reverse(new_next_checks)
  end

  def surrounding_points(state, {x,y,z}) do
    [
      {x + 1, y, z},
      {x - 1, y, z},
      {x, y, z + 1},
      {x, y, z - 1},
    ] |> Enum.filter(fn point -> needs_to_be_filled?(state, point) end)
  end

  def find_leftmost_possible_start_point(state, maybe_start_point) do
    find_leftmost_possible_start_point(state, maybe_start_point, 0)
  end
  def find_leftmost_possible_start_point(state, {x,y,z}, count) when count < @max_fill do
    maybe_next = {x-1, y, z}
    if needs_to_be_filled?(state, maybe_next) do
      find_leftmost_possible_start_point(state, maybe_next, count + 1)
    else
      {x,y,z}
    end
  end
  def find_leftmost_possible_start_point(_state, point, _count) do
    point
  end

  def find_next_level_start(state, next_line) do
    result = next_line |> Enum.find(fn {x,y,z} -> needs_to_be_filled?(state, {x,y+1,z}) end)
    case result do
      {a,b,c} -> {a, b+1, c}
      _ -> nil
    end
  end
end
