defmodule Nanobots.CLI do
  def main([path]) when is_binary(path) do
    main([path, "StepUp"])
  end
  def main([path, strategy]) when is_binary(path) and is_binary(strategy) do
    strategy =
      String.to_existing_atom("Elixir.Nanobots.Strategies.#{strategy}")
    path
    |> Nanobots.Solver.new(strategy)
    |> Nanobots.Solver.solve
    |> IO.inspect
  end
  def main(_args) do
    IO.puts "USAGE:  nanobots MODEL_FILE_PATH"
  end
end
