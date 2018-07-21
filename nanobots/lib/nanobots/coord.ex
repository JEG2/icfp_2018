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

  def closest({x, y, z}, layer) do
  end

  def near_goal({x, y, z}) do
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
  end

  def to_d({src_x, src_y, src_z}, {dst_x, dst_y, dst_z}) do
    {abs(dst_x - src_x), abs(dst_y - src_y), abs(dst_z - src_z)}
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
end
