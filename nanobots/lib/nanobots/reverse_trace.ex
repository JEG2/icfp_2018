defmodule Nanobots.ReverseTrace do
  alias Nanobots.Trace
  # alias Nanobots.Commands.{
  #   Halt, Wait, Flip, SMove, LMove, Fill, Void, GFill, GVoid,
  #   Fission, FusionP, FusionS
  # }
  alias Nanobots.Commands.{
    Halt, Wait, Flip, SMove, LMove, Fill, Void, GFill, GVoid
  }

  defstruct ~w[path commands]a

  def new(path), do: %__MODULE__{path: path, commands: [ ]}

  def record_timestep(%__MODULE__{commands: commands} = trace, new_commands)
  when is_list(new_commands) do
    combined =
      new_commands
      |> Enum.map(fn command -> reverse_command(command) end)
      |> Enum.reverse
      |> Kernel.++(commands)
    %__MODULE__{trace | commands: combined}
  end
  def record_timestep(trace, _commands), do: trace

  defp reverse_command(%Halt{ } = halt), do: halt
  defp reverse_command(%Wait{ } = wait), do: wait
  defp reverse_command(%Flip{ } = flip), do: flip
  defp reverse_command(%SMove{lld: {dx, dy, dz}}) do
    %SMove{lld: {-dx, -dy, -dz}}
  end
  defp reverse_command(
    %LMove{sld1: {dx1, dy1, dz1}, sld2: {dx2, dy2, dz2}}
  ) do
    %LMove{sld1: {-dx2, -dy2, -dz2}, sld2: {-dx1, -dy1, -dz1}}
  end
  # defp reverse_command(%FusionP{nd: dx_dy_dz}) do
  #   nd = dx_dy_dz_to_nd(dx_dy_dz)
  #   <<nd::size(5), 0b111::size(3)>>
  # end
  # defp reverse_command(%FusionS{nd: dx_dy_dz}) do
  #   nd = dx_dy_dz_to_nd(dx_dy_dz)
  #   <<nd::size(5), 0b110::size(3)>>
  # end
  # defp reverse_command(%Fission{nd: dx_dy_dz, m: m}) do
  #   nd = dx_dy_dz_to_nd(dx_dy_dz)
  #   << nd::size(5), 0b101::size(3),
  #      m >>
  # end
  defp reverse_command(%Fill{nd: dx_dy_dz}), do: %Void{nd: dx_dy_dz}
  defp reverse_command(%Void{nd: dx_dy_dz}), do: %Fill{nd: dx_dy_dz}
  defp reverse_command(%GFill{nd: dx_dy_dz, fd: fd}) do
    %GVoid{nd: dx_dy_dz, fd: fd}
  end
  defp reverse_command(%GVoid{nd: dx_dy_dz, fd: fd}) do
    %GFill{nd: dx_dy_dz, fd: fd}
  end

  def close(%__MODULE__{path: path, commands: commands}) do
    trace = Trace.new(path)
    commands
    |> Enum.drop(1)
    |> Enum.each(fn command -> Trace.record_timestep(trace, [command]) end)
    Trace.record_timestep(trace, [%Halt{ }])
    Trace.close(trace)
  end
  def close(_), do: nil
end
