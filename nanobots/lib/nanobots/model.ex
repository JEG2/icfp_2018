defmodule Nanobots.Model do
  defstruct ~w[resolution matrix]a

  def from_file(path) do
    File.open!(path, ~w[read]a, &parse_model/1)
  end

  defp parse_model(device) do
    <<resolution::integer>> = IO.binread(device, 1)
    voxels = resolution |> :math.pow(3) |> trunc
    bytes = voxels |> Kernel./(8) |> Float.ceil |> trunc
    full_list =
      device
      |> IO.binread(bytes)
      |> Stream.unfold(fn
        <<full::size(1), rest::bitstring>> -> {full, rest}
        "" -> nil
      end)
      |> Enum.chunk_every(8)
      |> Enum.map(fn byte -> Enum.reverse(byte) end)
      |> List.flatten
      |> Enum.take(voxels)
    matrix =
      for x <- 0..(resolution - 1),
          y <- 0..(resolution - 1),
          z <- 0..(resolution - 1) do
        {x, y, z}
      end
      |> Enum.zip(full_list)
      |> Enum.filter(fn {_xyz, full} -> full == 1 end)
      |> Enum.map(fn {xyz, _full} -> xyz end)
      |> MapSet.new
    %__MODULE__{resolution: resolution, matrix: matrix}
  end

  def filled?(%__MODULE__{matrix: matrix}, coord) do
    MapSet.member?(matrix, coord)
  end

  def fill(%__MODULE__{matrix: matrix} = model, coords) when is_list coords do
    %__MODULE__{model | matrix: MapSet.union(matrix, MapSet.new(coords))}
  end
  def fill(%__MODULE__{matrix: matrix} = model, coord) do
    %__MODULE__{model | matrix: MapSet.put(matrix, coord)}
  end

  def void(%__MODULE__{matrix: matrix} = model, coords) when is_list coords do
    %__MODULE__{model | matrix: MapSet.difference(matrix, MapSet.new(coords))}
  end
  def void(%__MODULE__{matrix: matrix} = model, coord) do
    %__MODULE__{model | matrix: MapSet.delete(matrix, coord)}
  end

  def y_layer(%__MODULE__{matrix: matrix}, y) do
    matrix
    |> Enum.filter(fn {_x, ^y, _z} -> true; xyz -> false end)
    |> MapSet.new
  end
end
