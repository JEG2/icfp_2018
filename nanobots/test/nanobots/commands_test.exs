defmodule Nanobots.CommandsTest do
  use ExUnit.Case
  alias Nanobots.Bot
  alias Nanobots.Commands.{Halt, Wait, Flip, SMove, LMove, Fill, Void, Fission, FusionP, FusionS}

  describe "Halt.from_bot" do
    test "returns a struct with volatiles" do
      result = Halt.from_bot(%Bot{pos: {0,0,0}})
      assert result.volatiles == MapSet.new([{0,0,0}])
    end
  end

  describe "Wait.from_bot" do
    test "returns a struct with volatiles" do
      bot_position = {13,45,10}
      result = Wait.from_bot(%Bot{pos: bot_position})
      assert result.volatiles == MapSet.new([bot_position])
    end
  end

  describe "Flip.from_bot" do
    test "returns a struct with volatiles" do
      bot_position = {13,45,10}
      result = Flip.from_bot(%Bot{pos: bot_position})
      assert result == %Flip{volatiles: MapSet.new([bot_position])}
    end
  end

  describe "SMove.from_bot" do
    test "returns a struct with lld, volatiles" do
      start = {8,15,17}
      lld = {13,0,0}
      result = SMove.from_bot(%Bot{pos: start}, lld)
      expected_volatiles = MapSet.new([
        start,
        {9, 15, 17},
        {10, 15, 17},
        {11, 15, 17},
        {12, 15, 17},
        {13, 15, 17},
        {14, 15, 17},
        {15, 15, 17},
        {16, 15, 17},
        {17, 15, 17},
        {18, 15, 17},
        {19, 15, 17},
        {20, 15, 17},
        {21, 15, 17}
      ])
      assert result.lld == lld
      assert result.volatiles == expected_volatiles
    end
  end

  describe "LMove.from_bot" do
    test "returns a struct with sld1, sld2, volatiles" do
      start = {8,15,17}
      sld1 = {4,0,0}
      sld2 = {0,0,3}
      result = LMove.from_bot(%Bot{pos: start}, sld1, sld2)
      expected_volatiles = MapSet.new([
        start,
        {9, 15, 17},
        {10, 15, 17},
        {11, 15, 17},
        {12, 15, 17},
        {12, 15, 18},
        {12, 15, 19},
        {12, 15, 20},
      ])
      assert result.sld1 == sld1
      assert result.sld2 == sld2
      assert result.volatiles == expected_volatiles
    end
  end

  describe "Fill.from_bot" do
    test "returns struct with nd, volatiles" do
      start = {8,15,17}
      nd = {1,0,0}
      c_prime = {9,15,17}
      result = Fill.from_bot(%Bot{pos: start}, nd)
      assert result.nd == nd
      assert result.volatiles == MapSet.new([start, c_prime])
    end
  end

  describe "Void.from_bot" do
    test "returns struct with nd, volatiles" do
      start = {8,15,17}
      nd = {1,0,0}
      c_prime = {9,15,17}
      result = Void.from_bot(%Bot{pos: start}, nd)
      assert result.nd == nd
      assert result.volatiles == MapSet.new([start, c_prime])
    end
  end

  describe "Fission.from_bot" do
    test "returns struct with nd, m, volatiles" do
      start = {8,15,17}
      nd = {1,0,0}
      c_prime = {9,15,17}
      m = 2
      result = Fission.from_bot(%Bot{pos: start}, nd, m)
      assert result.nd == nd
      assert result.m == m
      assert result.volatiles == MapSet.new([start, c_prime])
    end
  end

  describe "FusionP.from_bot" do
    test "returns struct with nd, volatiles" do
      start = {8,15,17}
      nd = {1,0,0}
      c_prime = {9,15,17}
      result = FusionP.from_bot(%Bot{pos: start}, nd)
      assert result.nd == nd
      assert result.volatiles == MapSet.new([start, c_prime])
    end
  end

  describe "FusionS.from_bot" do
    test "returns struct with nd, volatiles" do
      start = {8,15,17}
      nd = {1,0,0}
      result = FusionS.from_bot(%Bot{pos: start}, nd)
      assert result.nd == nd
      assert result.volatiles == MapSet.new
    end
  end
end
