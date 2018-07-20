defmodule NanobotsTest do
  use ExUnit.Case
  doctest Nanobots

  test "greets the world" do
    assert Nanobots.hello() == :world
  end
end
