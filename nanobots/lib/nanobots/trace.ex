defmodule Nanobots.Trace do
  defstruct ~w[device]a

  @moduledoc ~S"""
  alias Nanobots.Trace

  trace = Trace.new("test.nbt")

  Trace.record_timestep(trace, [%{command: {:fission, {0, 0, 1}, 5}}])
  Trace.record_timestep(trace, [%{command: {:fusion_p, {-1, 1, 0}}}])
  Trace.record_timestep(trace, [%{command: {:fusion_s, {1, -1, 0}}}])
  Trace.record_timestep(trace, [%{command: {:flip}}])
  Trace.record_timestep(trace, [%{command: {:wait}}])
  Trace.record_timestep(trace, [%{command: {:s_move, {12, 0, 0}}}])
  Trace.record_timestep(trace, [%{command: {:s_move, {0, 0, -4}}}])
  Trace.record_timestep(trace, [%{command: {:l_move, {3, 0, 0}, {0, -5, 0}}}])
  Trace.record_timestep(trace, [%{command: {:l_move, {0, -2, 0}, {0, 0, 2}}}])
  Trace.record_timestep(trace, [%{command: {:fill, {0, -1, 0}}}])
  Trace.record_timestep(trace, [%{command: {:halt}}])

  Trace.close(trace)
  """

  def new(path), do: %__MODULE__{device: File.open!(path, ~w[write]a)}

  def record_timestep(%__MODULE__{device: device}, bots) when is_list(bots) do
    Enum.each(bots, fn %{command: command} ->
      encoded = encode_command(command)
      IO.binwrite(device, encoded)
    end)
  end

  defp encode_command({:halt}), do: <<0b11111111>>
  defp encode_command({:wait}), do: <<0b11111110>>
  defp encode_command({:flip}), do: <<0b11111101>>
  defp encode_command({:s_move, lld}) do
    {lld_a, lld_i} = ld_to_a_and_i(lld, 15)
    << 0b00::size(2), lld_a::size(2), 0b0100::size(4),
       0b000::size(3), lld_i::size(5) >>
  end
  defp encode_command({:l_move, sld_1, sld_2}) do
    {sld_1_a, sld_1_i} = ld_to_a_and_i(sld_1, 5)
    {sld_2_a, sld_2_i} = ld_to_a_and_i(sld_2, 5)
    << sld_2_a::size(2), sld_1_a::size(2), 0b1100::size(4),
       sld_2_i::size(4), sld_1_i::size(4) >>
  end
  defp encode_command({:fusion_p, dx_dy_dz}) do
    nd = dx_dy_dz_to_nd(dx_dy_dz)
    <<nd::size(5), 0b111::size(3)>>
  end
  defp encode_command({:fusion_s, dx_dy_dz}) do
    nd = dx_dy_dz_to_nd(dx_dy_dz)
    <<nd::size(5), 0b110::size(3)>>
  end
  defp encode_command({:fission, dx_dy_dz, m}) do
    nd = dx_dy_dz_to_nd(dx_dy_dz)
    << nd::size(5), 0b101::size(3),
       m >>
  end
  defp encode_command({:fill, dx_dy_dz}) do
    nd = dx_dy_dz_to_nd(dx_dy_dz)
    <<nd::size(5), 0b011::size(3)>>
  end

  defp ld_to_a_and_i({x, 0, 0}, offset), do: {0b01, x + offset}
  defp ld_to_a_and_i({0, y, 0}, offset), do: {0b10, y + offset}
  defp ld_to_a_and_i({0, 0, z}, offset), do: {0b11, z + offset}

  defp dx_dy_dz_to_nd({dx, dy, dz}) do
    (dx + 1) * 9 + (dy + 1) * 3 + (dz + 1)
  end

  def close(%__MODULE__{device: device}), do: File.close(device)
end
