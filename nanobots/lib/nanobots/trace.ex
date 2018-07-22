defmodule Nanobots.Trace do
  alias Nanobots.Commands.{
    Halt, Wait, Flip, SMove, LMove, Fill, Void, GFill, GVoid, Fission, FusionP, FusionS
  }

  defstruct ~w[device]a

  @moduledoc ~S"""
  alias Nanobots.Trace
  alias Nanobots.Commands.{
    Halt, Wait, Flip, SMove, LMove, Fill, Fission, FusionP, FusionS
  }

  trace = Trace.new("test.nbt")

  Trace.record_timestep(trace, [%Fission{nd: {0, 0, 1}, m: 5}])
  Trace.record_timestep(trace, [%FusionP{nd: {-1, 1, 0}}])
  Trace.record_timestep(trace, [%FusionS{nd: {1, -1, 0}}])
  Trace.record_timestep(trace, [%Flip{ }])
  Trace.record_timestep(trace, [%Wait{ }])
  Trace.record_timestep(trace, [%SMove{lld: {12, 0, 0}}])
  Trace.record_timestep(trace, [%SMove{lld: {0, 0, -4}}])
  Trace.record_timestep(trace, [%LMove{sld1: {3, 0, 0}, sld2: {0, -5, 0}}])
  Trace.record_timestep(trace, [%LMove{sld1: {0, -2, 0}, sld2: {0, 0, 2}}])
  Trace.record_timestep(trace, [%Fill{nd: {0, -1, 0}}])
  Trace.record_timestep(trace, [%Halt{ }])

  Trace.close(trace)
  """

  def new(path), do: %__MODULE__{device: File.open!(path, ~w[write]a)}

  def record_timestep(%__MODULE__{device: device}, commands)
  when is_list(commands) do
    Enum.each(commands, fn command ->
      encoded = encode_command(command)
      IO.binwrite(device, encoded)
    end)
  end
  def record_timestep(_trace, _commands), do: nil

  defp encode_command(%Halt{ }), do: <<0b11111111>>
  defp encode_command(%Wait{ }), do: <<0b11111110>>
  defp encode_command(%Flip{ }), do: <<0b11111101>>
  defp encode_command(%SMove{lld: lld}) do
    {lld_a, lld_i} = ld_to_a_and_i(lld, 15)
    << 0b00::size(2), lld_a::size(2), 0b0100::size(4),
       0b000::size(3), lld_i::size(5) >>
  end
  defp encode_command(%LMove{sld1: sld1, sld2: sld2}) do
    {sld1_a, sld1_i} = ld_to_a_and_i(sld1, 5)
    {sld2_a, sld2_i} = ld_to_a_and_i(sld2, 5)
    << sld2_a::size(2), sld1_a::size(2), 0b1100::size(4),
       sld2_i::size(4), sld1_i::size(4) >>
  end
  defp encode_command(%FusionP{nd: dx_dy_dz}) do
    nd = dx_dy_dz_to_nd(dx_dy_dz)
    <<nd::size(5), 0b111::size(3)>>
  end
  defp encode_command(%FusionS{nd: dx_dy_dz}) do
    nd = dx_dy_dz_to_nd(dx_dy_dz)
    <<nd::size(5), 0b110::size(3)>>
  end
  defp encode_command(%Fission{nd: dx_dy_dz, m: m}) do
    nd = dx_dy_dz_to_nd(dx_dy_dz)
    << nd::size(5), 0b101::size(3),
       m >>
  end
  defp encode_command(%Fill{nd: dx_dy_dz}) do
    nd = dx_dy_dz_to_nd(dx_dy_dz)
    <<nd::size(5), 0b011::size(3)>>
  end
  defp encode_command(%Void{nd: dx_dy_dz}) do
    nd = dx_dy_dz_to_nd(dx_dy_dz)
    <<nd::size(5), 0b010::size(3)>>
  end
  defp encode_command(%GFill{nd: dx_dy_dz, fd: fd}) do
    nd = dx_dy_dz_to_nd(dx_dy_dz)
    {fx, fy, fz} = binary_fd(fd)
    << nd::size(5), 0b001::size(3),
       fx::size(8), fy::size(8), fz::size(8) >>
  end
  defp encode_command(%GVoid{nd: dx_dy_dz, fd: fd}) do
    nd = dx_dy_dz_to_nd(dx_dy_dz)
    {fx, fy, fz} = binary_fd(fd)
    << nd::size(5), 0b000::size(3),
       fx::size(8), fy::size(8), fz::size(8) >>
  end

  defp ld_to_a_and_i({x, 0, 0}, offset), do: {0b01, x + offset}
  defp ld_to_a_and_i({0, y, 0}, offset), do: {0b10, y + offset}
  defp ld_to_a_and_i({0, 0, z}, offset), do: {0b11, z + offset}

  defp dx_dy_dz_to_nd({dx, dy, dz}) do
    (dx + 1) * 9 + (dy + 1) * 3 + (dz + 1)
  end

  defp binary_fd({fx, fy, fz}) do
    {fx + 30, fy + 30, fz + 30}
  end

  def close(%__MODULE__{device: device}), do: File.close(device)
  def close(_), do: nil
end
