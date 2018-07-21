defmodule Nanobots.CoordTest do
  use ExUnit.Case
  alias Nanobots.Coord

  test "mlen" do
    assert Coord.mlen({0,7,0}) == 7
    assert Coord.mlen({0,-7,0}) == 7
    assert Coord.mlen({1,2,3}) == 6
  end

  test "calculate_cprime" do
    assert Coord.calculate_cprime({1,1,1}, {0,1,0}) == {1,2,1}
    assert Coord.calculate_cprime({1,1,1}, {1,2,3}) == {2,3,4}
    assert Coord.calculate_cprime({5,5,5}, {1,2,-3}) == {6,7,2}
  end

  test "coordinate_difference" do
    assert Coord.difference({1,1,1}, {1,1,2}) == {0,0,1}
  end
end
