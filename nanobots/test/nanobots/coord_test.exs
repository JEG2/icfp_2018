defmodule Nanobots.CoordTest do
  use ExUnit.Case
  alias Nanobots.Coord

  test "mlen" do
    assert Coord.mlen({0,7,0}) == 7
    assert Coord.mlen({0,-7,0}) == 7
    assert Coord.mlen({1,2,3}) == 6
  end

  test "clen" do
    assert Coord.clen({0,7,0}) == 7
    assert Coord.clen({0,-7,0}) == 7
    assert Coord.clen({1,2,3}) == 3
  end

  test "calculate_cprime" do
    assert Coord.calculate_cprime({1,1,1}, {0,1,0}) == {1,2,1}
    assert Coord.calculate_cprime({1,1,1}, {1,2,3}) == {2,3,4}
    assert Coord.calculate_cprime({5,5,5}, {1,2,-3}) == {6,7,2}
  end

  test "coordinate_difference" do
    assert Coord.difference({1,1,1}, {1,1,2}) == {0,0,1}
  end

  test "valid_fd?" do
    assert Coord.valid_fd?({1,1,0})
    assert Coord.valid_fd?({30,1,0})
    assert Coord.valid_fd?({-17,0,19})
    assert Coord.valid_fd?({30,30,0})
    assert Coord.valid_fd?({1,2,3})
    assert Coord.valid_fd?({30,30,30})
    assert Coord.valid_fd?({30,-30,30})

    refute Coord.valid_fd?({0,0,0})
    refute Coord.valid_fd?({31,0,0})
    refute Coord.valid_fd?({-31,0,30})
    refute Coord.valid_fd?({40,0,0})
  end

  test "calculate garea of a straight line" do
    assert Coord.garea({1,2,3}, {1,0,0}, {5,0,0}) == [
      {2,2,3},
      {3,2,3},
      {4,2,3},
      {5,2,3},
      {6,2,3},
    ]

    assert Coord.garea({30,40,50}, {0,-1,0}, {0,-3,0}) == [
      {30,39,50},
      {30,38,50},
      {30,37,50},
    ]
  end

  test "calculate garea of a plane" do
    assert Coord.garea({1,2,3}, {1,1,0}, {3,0,0}) == [
      {2,3,3},
      {2,2,3},
      {3,3,3},
      {3,2,3},
      {4,3,3},
      {4,2,3}
    ]
  end

  test "calculate garea of a box" do
    assert Coord.garea({1,2,3}, {1,1,0}, {3,0,1}) == [
      {2,3,3},
      {2,3,4},
      {2,2,3},
      {2,2,4},
      {3,3,3},
      {3,3,4},
      {3,2,3},
      {3,2,4},
      {4,3,3},
      {4,3,4},
      {4,2,3},
      {4,2,4},
    ]
  end
end
