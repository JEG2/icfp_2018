defmodule Nanobots.Strategy do
  @callback move(state::struct, memory::map) :: {[any], map}
end
