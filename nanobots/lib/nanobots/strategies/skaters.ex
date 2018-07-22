defmodule Nanobots.Strategies.Skaters do
  alias Nanobots.{Coord, Model, Pathfinder, Bot}
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
                 |> Map.put(:next_check, [{0, 0, 0}])
                 |> Map.put(:start_of_line, nil)
                 |> Map.put(:end_of_line, nil)
    {[%Fission{nd: {1,0,0}, m: 0}], new_memory}
  end
  def move(state, memory = %{move_queue: move_queue}) when length(move_queue) > 0 do
    {Tuple.to_list(hd(move_queue)), %{memory | move_queue: tl(move_queue)}}
  end
  def move(state, memory = %{phase: :move_for_fill}) do
    miki_bot = List.first(state.bots)
    stephen_bot = List.last(state.bots)
    next_line = find_next_line(state, memory.next_check)
    start_of_line = List.last(next_line) # yes last
    end_of_line = List.first(next_line) # yes first
    miki_goal = find_near_destination(state, next_line, start_of_line)
    stephen_goal = find_near_destination(state, next_line, end_of_line)
    miki_bot_path = Pathfinder.path(miki_bot.pos, miki_goal, state.matrix, [])
    miki_bot_moves = Pathfinder.to_moves(miki_bot, miki_bot_path)
    stephen_bot_path = Pathfinder.path(stephen_bot.pos, stephen_goal, state.matrix, [])
    stephen_bot_moves = Pathfinder.to_moves(stephen_bot, stephen_bot_path)
    {miki_bot_moves, stephen_bot_moves} = pad_with_waits(miki_bot_moves, stephen_bot_moves)
    [next_moves | queued_moves] = Enum.zip(miki_bot_moves, stephen_bot_moves)
    {Tuple.to_list(next_moves), %{memory |
      move_queue: queued_moves,
      phase: :fill,
      start_of_line: start_of_line,
      end_of_line: end_of_line
    }}
  end
  def move(state, memory = %{phase: :fill}) do
    miki_bot = List.first(state.bots)
    miki_nd = Coord.difference(miki_bot.pos, memory.start_of_line)
    miki_fd = Coord.difference(memory.start_of_line, memory.end_of_line)

    stephen_bot = List.last(state.bots)
    stephen_nd = Coord.difference(stephen_bot.pos, memory.end_of_line)
    stephen_fd = Coord.difference(memory.end_of_line, memory.start_of_line)

    next_moves = [%GFill{nd: miki_nd, fd: miki_fd}, %GFill{nd: stephen_nd, fd: stephen_fd}]
    # next_moves = [%Wait{}, %Wait{}]
    {next_moves, %{memory | phase: :prep_for_fusion}}
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
    {miki_bot_moves, stephen_bot_moves} = pad_with_waits(miki_bot_moves, stephen_bot_moves)
    [next_moves | queued_moves] = Enum.zip(miki_bot_moves, stephen_bot_moves)
    {Tuple.to_list(next_moves), %{memory |
      move_queue: queued_moves,
      phase: :fusion
    }}
  end
  def move(state, memory = %{phase: :fusion}) do
    next_moves = [%FusionP{nd: {1,0,0}}, %FusionS{nd: {-1,0,0}}]
    {next_moves, %{memory | phase: :end}}
  end
  def move(state, memory = %{phase: :end}) do
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

  # def populate_move_queue(state, memory) do new_memory = memory |> Map.put(:phase, :skating_partner) |> Map.put(:bots, []) |> Map.put(:next_line, []) |> Map.put(:from_point, {0,0,0}) |> Map.put(:matrix, state.matrix) populate_move_queue(state, new_memory, []) # start_of_next_line = find_start_of_next_line(state) next_line = find_longest_possible_continuous_line(state, start_of_next_line) move_destination = find_near_destination(state, memory, next_line, start_of_next_line)
  #   # miki_bot = state.bots |> Enum.find(fn bot -> bot.bid == 1 end)
  #   # miki_bot_path = Pathfinder.path(miki_bot.pos, move_destination, state.matrix, [])
  #   # miki_bot_moves = Pathfinder.to_moves(miki_bot, miki_bot_path)
  #   # queue = if (Enum.empty?(miki_bot_moves)) do
  #   #   if need_a_partner?(memory.bots) do
  #   #     [[%Fission{nd: start_of_next_line}] | queue]
  #   #   else
  #   #     stephen_bot = state.bots |> Enum.find(fn bot -> bot.bid == 2 end)
  #   #     stephen_bot_path = Pathfinder.path(stephen_bot.pos, move_destination, state.matrix, [])
  #   #     stephen_bot_moves = Pathfinder.to_moves(stephen_bot, stephen_bot_path)
  #   #     [stephen_bot_moves | queue]
  #   #   end
  #   # else
  #   #   [miki_bot_moves | queue]
  #   # end

  #   # Enum.reverse(queue)
  # end
  # def populate_move_queue(state, memory = %{phase: :end}, queue) do
  #   Enum.reverse(queue)
  # end
  # def populate_move_queue(state, memory = %{phase: :stage_for_fill}, queue) do
  #   new_memory = %{memory | phase: :move_for_fill, next_line: find_next_line(state, memory)}
  #   populate_move_queue(state, new_memory, queue)
  # end
  # def populate_move_queue(state, memory = %{phase: :move_for_fill}, queue) do
  #   [miki | stephen] = memory.bots
  #   miki_destination = List.first(memory.next_line)
  #   stephen_destination = List.last(memory.next_line)
  #   miki_path = Pathfinder.path(miki, miki_destination, memory.matrix, [])
  #   # miki_moves = Pathfinder.

  #   queue = [[%Wait{}, %Wait{}] | queue]
  #   populate_move_queue(state, %{memory | phase: :end}, queue)
  # end
  # def populate_move_queue(state, memory = %{phase: :skating_partner}, queue) do
  #   new_memory = %{memory | phase: :stage_for_fill, bots: [{0,0,0}, {0,0,1}]}
  #   populate_move_queue(state, new_memory, [[%Fission{nd: {0,0,1}, m: 0}] | queue])
  # end

  # def need_a_partner?(bots) do
  #   bots == 1
  # end

  def find_next_line(state, [starting_point | _rest_to_check]) do
    start = find_start_of_next_line(state, starting_point)
    find_longest_possible_continuous_line(state, start)
  end

  def find_start_of_next_line(state, {x, y, z}) do
    case Nanobots.Model.filled?(state.model, {x, y, z}) do
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
  def find_longest_possible_continuous_line(state, point, line) when length(line) >= @max_fill do
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
    Nanobots.Model.filled?(state.model, point) && !Nanobots.Model.filled?(state.matrix, point)
  end

  def possible_destination(state, memory, point) do
    !Nanobots.Model.filled?(state.matrix, point)
  end

  def find_near_destination(state, line, point) do
    possible_destinations = Coord.near(point, state.model.resolution)
    possible_destinations
    |> Enum.reject(fn destination -> destination in line end)
    |> Enum.find(fn destination -> !Nanobots.Model.filled?(state.matrix, point) end)
  end
end
