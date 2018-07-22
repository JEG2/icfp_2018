defmodule Nanobots.Strategies.Grounder do
  alias Nanobots.{Bot, Coord, Model, Pathfinder}
  alias Nanobots.Commands.{Halt, Fill, SMove, Void}

  @behaviour Nanobots.Strategy

  def move(state, memory) do
    unless state.problem == :assemble do
      raise "Problem type mismatch"
    end

    move_queue = Map.get(memory, :move_queue, [ ])
    if move_queue != [ ] do
      {[hd(move_queue)], Map.put(memory, :move_queue, tl(move_queue))}
    else
      phase = Map.get(memory, :phase, :setup)
      apply(__MODULE__, phase, [state, memory])
    end
  end

  def setup(state, _memory) do
    memory = %{
      phase: :seek,
      grounded: Model.y_layer(state.model, 0),
      layer: 0
    }
    seek(state, memory)
  end

  def seek(state, memory) do
    me = hd(state.bots)
    if MapSet.size(memory.grounded) > 0 do
      build_from =
        memory.grounded
        |> Enum.filter(fn {_x, y, _z} -> y == memory.layer end)
        |> Enum.flat_map(fn voxel ->
          Coord.near(voxel, state.model.resolution)
        end)
        |> MapSet.new
        |> MapSet.delete(me.pos)
        |> MapSet.difference(state.matrix.matrix)
        |> Enum.sort_by(fn voxel ->
          {
            voxel
            |> Coord.near(state.model.resolution)
            |> MapSet.new
            |> MapSet.intersection(memory.grounded)
            |> MapSet.size
            |> Kernel.-,
            me.pos
            |> Coord.to_d(voxel)
            |> Coord.mlen,
            voxel
          }
        end)
        |> hd
      path = Pathfinder.path(me.pos, build_from, state.matrix, [ ])
      move_queue =
        if path do
          Pathfinder.to_moves(me, path)
        else
          one_up = {elem(me.pos, 0), elem(me.pos, 1) + 1, elem(me.pos, 2)}
          two_up = {elem(me.pos, 0), elem(me.pos, 1) + 2, elem(me.pos, 2)}
          [
            Void.from_bot(me, Coord.to_d(me.pos, one_up)),
            SMove.from_bot(me, Coord.to_d(me.pos, two_up)),
            Fill.from_bot(%Bot{me | pos: two_up}, Coord.to_d(two_up, one_up))
          ]
        end
      {
        [hd(move_queue)],
        memory
        |> Map.put(:move_queue, tl(move_queue))
        |> Map.put(:phase, :build)
      }
    else
      go_home(state, Map.put(memory, :phase, :go_home))
    end
  end

  def build(state, memory) do
    me = hd(state.bots)
    safe =
      me.pos
      |> Coord.near(state.model.resolution)
      |> Enum.filter(fn {_x, y, _z} -> y == memory.layer end)
      |> MapSet.new
      |> MapSet.intersection(memory.grounded)
      |> MapSet.to_list
      |> List.first
    if safe do
      newly_grounded =
        safe
        |> Coord.adjacent(state.model.resolution)
        |> Enum.filter(fn voxel ->
          MapSet.member?(state.model.matrix, voxel) and
            not MapSet.member?(state.matrix.matrix, voxel)
        end)
      new_grounded =
        memory.grounded
        |> MapSet.delete(safe)
        |> MapSet.union(MapSet.new(newly_grounded))
      new_layer =
        new_grounded
        |> Enum.map(fn {_x, y, _z} -> y end)
        |> Enum.uniq
        |> Enum.min(fn -> nil end)
      {
        [Fill.from_bot(me, Coord.to_d(me.pos, safe))],
        %{
          memory |
          grounded: new_grounded,
          layer: new_layer
        }
      }
    else
      seek(state, Map.put(memory, :phase, :seek))
    end
  end

  def go_home(state, memory) do
    me = hd(state.bots)
    path = Pathfinder.path(me.pos, {0, 0, 0}, state.matrix, [ ])
    move_queue =
      if path do
        Pathfinder.to_moves(me, path) ++ [Halt.from_bot(me)]
      else
        one_up = {elem(me.pos, 0), elem(me.pos, 1) + 1, elem(me.pos, 2)}
        two_up = {elem(me.pos, 0), elem(me.pos, 1) + 2, elem(me.pos, 2)}
        escape_path = Pathfinder.path(two_up, {0, 0, 0}, state.matrix, [ ])
        [
          Void.from_bot(me, Coord.to_d(me.pos, one_up)),
          SMove.from_bot(me, Coord.to_d(me.pos, two_up)),
          Fill.from_bot(%Bot{me | pos: two_up}, Coord.to_d(two_up, one_up))
        ] ++
          Pathfinder.to_moves(me, escape_path) ++
          [Halt.from_bot(me)]
      end
    {[hd(move_queue)], Map.put(memory, :move_queue, tl(move_queue))}
  end
end
