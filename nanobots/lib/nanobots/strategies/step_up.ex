defmodule Nanobots.Strategies.StepUp do
  alias Nanobots.{Coord, Model, Pathfinder}
  alias Nanobots.Commands.{Halt, Fill}

  @behaviour Nanobots.Strategy

  def move(state, memory) do
    move_queue = Map.get(memory, :move_queue, [ ])
    if move_queue != [ ] do
      {[hd(move_queue)], Map.put(memory, :move_queue, tl(move_queue))}
    else
      phase = Map.get(memory, :phase, :step_up)
      apply(__MODULE__, phase, [state, memory])
    end
  end

  def step_up(state, memory) do
    me = hd(state.bots)
    memory = Map.put_new_lazy(
      memory,
      :layer,
      fn -> Model.y_layer(state.model, me.pos |> elem(1)) end
    )

    if MapSet.size(memory.layer) > 0 do
      goal = Coord.closest(me.pos, memory.layer)
      near_goal = Coord.near(goal, state.matrix.resolution)
      fill_from = Coord.closest(me.pos, near_goal)
      path = Pathfinder.path(me.pos, fill_from, state.matrix, [ ])
      step = Pathfinder.path(
        fill_from,
        {elem(goal, 0), elem(goal, 1) + 1, elem(goal, 2)},
        %Model{state.matrix | matrix: MapSet.put(state.matrix.matrix, goal)},
        [ ]
      )
      move_queue =
        Pathfinder.to_moves(me, path) ++
          [Fill.from_bot(me, Coord.to_d(fill_from, goal))] ++
          Pathfinder.to_moves(me, step)
      {
        [hd(move_queue)],
        Map.merge(
          memory,
          %{
            layer: MapSet.delete(memory.layer, goal),
            move_queue: tl(move_queue),
            phase: :go_home
            # phase: :fill_from_above
          }
        )
      }
    else
      go_home(state, %{memory | phase: :go_home})
    end
  end

  # def fill_from(state, memory) do
    
  # end

  def go_home(state, memory) do
    me = hd(state.bots)
    path = Pathfinder.path(me.pos, {0, 0, 0}, state.matrix, [ ])
    move_queue = Pathfinder.to_moves(me, path) ++ [Halt.from_bot(me)]
    {[hd(move_queue)], Map.put(memory, :move_queue, tl(move_queue))}
  end
end
