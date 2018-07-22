defmodule Nanobots.Strategies.SkatersTest do
  use ExUnit.Case

  @pyramid_state Nanobots.State.from_model("../problemsF/FA027_tgt.mdl")
  # @gear_state Nanobots.State.from_model("../problemsF/FA003_tgt.mdl")

  test "find closest model point to start on the y=0 plane" do
    assert Nanobots.Strategies.Skaters.find_start_of_next_line(@pyramid_state, {0,0,0}) == {1,0,1}
  end

  test "move" do
    Nanobots.Solver.new("../problemsF/FA027_tgt.mdl", Nanobots.Strategies.Skaters)
    |> Nanobots.Solver.solve
  end
end
