defmodule Nanobots.Solver do
  alias Nanobots.State

  defstruct ~w[state strategy]a

  def new(path, strategy) do
    %__MODULE__{state: State.from_model(path), strategy: strategy}
  end

  def solve(%__MODULE__{state: state} = solver, strategy_memory \\ %{ }) do
    {commands, new_strategy_memory} =
      generate_timestep(solver, strategy_memory)
    new_state = State.apply(state, commands)
    if State.end?(new_state) do
      IO.puts new_state.energy
    else
      solve(%__MODULE__{solver | state: new_state}, new_strategy_memory)
    end
  end

  def generate_timestep(
    %__MODULE__{state: state, strategy: strategy},
    strategy_memory
  ) do
    strategy.move(state, strategy_memory)
  end
end
