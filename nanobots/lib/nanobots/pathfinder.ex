defmodule Nanobots.Pathfinder do
  alias Nanobots.{Bot, Coord}
  alias Nanobots.Commands.SMove

  def path(to, to, _matrix, _commands) do
    [to]
  end
  def path(from, to, matrix, commands) do
    unavailable = Enum.reduce(commands, MapSet.new, fn command, combined ->
      MapSet.union(combined, command.volatiles)
    end)
    {:ok, seen} = Agent.start_link(fn -> MapSet.new([from]) end)
    path = walk_path(matrix, [[from]], unavailable, to, seen)
    Agent.stop(seen)
    path
  end

  defp walk_path(_matrix, [ ], _unavailable, _to, _seen), do: nil
  defp walk_path(
    matrix,
    [[current | _voxels] = path | paths],
    unavailable,
    to,
    seen
  ) do
    steps =
      current
      |> Coord.moves(matrix, unavailable)
      |> Enum.reject(fn move ->
        Agent.get(seen, fn s -> MapSet.member?(s, move) end)
      end)
    if Enum.member?(steps, to) do
      [to | path] |> Enum.reverse
    else
      new_paths = steps |> Enum.map(fn step -> [step | path] end)
      Agent.update(seen, fn s -> steps |> MapSet.new |> MapSet.union(s) end)
      walk_path(
        matrix,
        paths ++ new_paths,
        MapSet.union(unavailable, MapSet.new(steps)),
        to,
        seen
      )
    end
  end

  def to_moves(_bot, voxels) when is_list(voxels) and length(voxels) < 2 do
    [ ]
  end
  def to_moves(%Bot{ } = bot, voxels) do
    voxels
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [from, to] ->
      SMove.from_bot(%Bot{bot | pos: from}, Coord.to_d(from, to))
    end)
  end
end
