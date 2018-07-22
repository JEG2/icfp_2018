defmodule Nanobots.Pathfinder do
  alias Nanobots.Coord
  alias Nanobots.Commands.SMove

  def path(to, to, _matrix, _commands) do
    [to]
  end
  def path(from, to, matrix, commands) do
    unavailable = Enum.reduce(commands, MapSet.new, fn command, combined ->
      MapSet.union(combined, command.volatiles)
    end)
    walk_path(matrix, [[from]], unavailable, to)
  end

  defp walk_path(_matrix, [ ], _unavailable, _to), do: nil
  defp walk_path(
    matrix,
    [[current | _voxels] = path | paths],
    unavailable,
    to
  ) do
    steps = current |> Coord.moves(matrix, unavailable)
    if Enum.member?(steps, to) do
      [to | path] |> Enum.reverse
    else
      new_paths = steps |> Enum.map(fn step -> [step | path] end)
      walk_path(
        matrix,
        paths ++ new_paths,
        MapSet.union(unavailable, MapSet.new(steps)),
        to
      )
    end
  end

  def to_moves(voxels) when is_list(voxels) and length(voxels) < 2 do
    [ ]
  end
  def to_moves(voxels) do
    voxels
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [from, to] -> %SMove{lld: Coord.to_d(from, to)} end)
  end
end
