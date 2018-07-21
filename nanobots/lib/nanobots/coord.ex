defmodule Nanobots.Coord do
  def calculate_cprime({cx, cy, cz}, {dx, dy, dz}) do
    {cx + dx, cy + dy, cz + dz}
  end

  def mlen({x, y, z}) do
    abs(x) + abs(y) + abs(z)
  end

  def difference({ax, ay, az}, {bx, by, bz}) do
    {bx - ax, by - ay, bz - az}
  end
end
