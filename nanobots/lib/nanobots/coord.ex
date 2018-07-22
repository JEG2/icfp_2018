defmodule Nanobots.Coord do
  @nds ( for x <- -1..1, y <- -1..1, z <- -1..1,
             abs(x) + abs(y) + abs(z) in [1, 2] do
               {x, y, z}
         end )

  def calculate_cprime({cx, cy, cz}, {dx, dy, dz}) do
    {cx + dx, cy + dy, cz + dz}
  end

  def mlen({x, y, z}) do
    abs(x) + abs(y) + abs(z)
  end

  def closest(xyz, voxels) do
    voxels
    |> Enum.map(fn voxel -> {xyz |> to_d(voxel) |> mlen, voxel} end)
    |> Enum.sort
    |> hd
    |> elem(1)
  end

  def near({x, y, z}, resolution) do
    [
      {x - 1, y - 1, z    },
      {x - 1, y    , z - 1},
      {x - 1, y    , z    },
      {x - 1, y    , z + 1},
      {x - 1, y + 1, z    },
      {x    , y - 1, z - 1},
      {x    , y - 1, z    },
      {x    , y - 1, z + 1},
      {x    , y    , z - 1},
      {x    , y    , z + 1},
      {x    , y + 1, z - 1},
      {x    , y + 1, z    },
      {x    , y + 1, z + 1},
      {x + 1, y - 1, z    },
      {x + 1, y    , z - 1},
      {x + 1, y    , z    },
      {x + 1, y    , z + 1},
      {x + 1, y + 1, z    }
    ]
    |> Enum.filter(&valid?(&1, resolution))
  end

  def adjacent({x, y, z}, resolution) do
    [
      {x - 1, y    , z    },
      {x    , y - 1, z    },
      {x    , y    , z - 1},
      {x    , y    , z + 1},
      {x    , y + 1, z    },
      {x + 1, y    , z    }
    ]
    |> Enum.filter(&valid?(&1, resolution))
  end

  def to_d({src_x, src_y, src_z}, {dst_x, dst_y, dst_z}) do
    {dst_x - src_x, dst_y - src_y, dst_z - src_z}
  end

  def clen({x, y, z}) do
    Enum.max([abs(x), abs(y), abs(z)])
  end

  def difference({ax, ay, az}, {bx, by, bz}) do
    {bx - ax, by - ay, bz - az}
  end

  def valid_fd?(fd) do
    0 < clen(fd) && clen(fd) <=30
  end

  def garea(start, near, far) when near in @nds do
    {nx, ny, nz} = calculate_cprime(start, near)
    {fx, fy, fz} = calculate_cprime(start, far)
    for x <- nx..fx, y <- ny..fy, z <- nz..fz do
      {x, y, z}
    end
  end

  def garea_dimensions({nx, ny, nz}, {fx, fy, fz}) do
    Enum.zip([nx, ny, nz], [fx, fy, fz])
    |> Enum.reduce(0, fn ({a,a}, dimensions) ->
      dimensions; (_, dimensions) -> dimensions + 1
    end)
  end

  def valid?({x, y, z}, resolution) do
    x >= 0 and x < resolution and
    y >= 0 and y < resolution and
    z >= 0 and z < resolution
  end

  def moves({x, y, z}, matrix, unavailable) do
    [
      {-1, 0, 0},
      {1, 0, 0},
      {0, -1, 0},
      {0, 1, 0},
      {0, 0, -1},
      {0, 0, 1}
    ]
    |> Enum.flat_map(fn {dx, dy, dz} ->
      Enum.reduce_while(1..15, [ ], fn i, voxels ->
        xyz = {x + dx * i, y + dy * i, z + dz * i}
        if valid?(xyz, matrix.resolution) and
           not MapSet.member?(matrix.matrix, xyz) and
           not MapSet.member?(unavailable, xyz) do
          {:cont, [xyz | voxels]}
        else
          {:halt, voxels}
        end
      end)
    end)
  end
end
