defmodule Nanobots.Strategies.StepUp do
  alias Nanobots.{Coord, Model, Pathfinder}
  alias Nanobots.Commands.{Halt, LMove, Fill}

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
      move_queue =
        Pathfinder.to_moves(path) ++
          [
            %Fill{nd: Coord.to_d(fill_from, goal)},
            %LMove{
              sld1: {0, 1, 0},
              sld2: Coord.to_d(
                {
                  elem(fill_from, 0),
                  elem(fill_from, 1) + 1,
                  elem(fill_from, 2)},
                {elem(goal, 0), elem(goal, 1) + 1, elem(goal, 2)}
              )
            }
          ]
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
    move_queue = Pathfinder.to_moves(path) ++ [%Halt{ }]
    {[hd(move_queue)], Map.put(memory, :move_queue, tl(move_queue))}
  end
end
