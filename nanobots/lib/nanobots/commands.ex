defmodule Nanobots.Commands do
  alias Nanobots.{Bot, Coord}

  defmodule Halt do
    defstruct ~w[volatiles]a

    def from_bot(%Bot{pos: pos}) do
      %__MODULE__{volatiles: MapSet.new([pos])}
    end
  end

  defmodule Wait do
    defstruct ~w[volatiles]a

    def from_bot(%Bot{pos: pos}) do
      %__MODULE__{volatiles: MapSet.new([pos])}
    end
  end

  defmodule Flip do
    defstruct ~w[volatiles]a

    def from_bot(%Bot{pos: pos}) do
      %__MODULE__{volatiles: MapSet.new([pos])}
    end
  end

  defmodule SMove do
    defstruct ~w[lld volatiles]a

    def from_bot(%Bot{pos: pos}, lld) do
      %__MODULE__{
        lld: lld,
        volatiles: MapSet.new(calculate_volatiles(pos, lld))
      }
    end

    def calculate_volatiles({x, y, z}, {dx, dy, dz})
    when dx < 0 or dy < 0 or dz < 0 do
      finish = {x + dx, y + dy, z + dz}
      calculate_volatile(finish, {-dx, -dy, -dz}, [finish])
    end
    def calculate_volatiles(start, difference) do
      calculate_volatile(start, difference, [start])
    end

    def calculate_volatile(_, {0,0,0}, volatiles) do
      volatiles |> Enum.reverse
    end
    def calculate_volatile(start, {dx, 0, 0}, volatiles) do
      next_step = Coord.calculate_cprime(start, {1, 0, 0})
      calculate_volatile(next_step, {dx-1, 0, 0}, [next_step | volatiles])
    end
    def calculate_volatile(start, {0, dy, 0}, volatiles) do
      next_step = Coord.calculate_cprime(start, {0, 1, 0})
      calculate_volatile(next_step, {0, dy-1, 0}, [next_step | volatiles])
    end
    def calculate_volatile(start, {0, 0, dz}, volatiles) do
      next_step = Coord.calculate_cprime(start, {0, 0, 1})
      calculate_volatile(next_step, {0, 0, dz-1}, [next_step | volatiles])
    end
  end

  defmodule LMove do
    defstruct ~w[sld1 sld2 volatiles]a

    def from_bot(%Bot{pos: pos}, sld1, sld2) do
      %__MODULE__{
        sld1: sld1,
        sld2: sld2,
        volatiles: MapSet.new(calculate_volatiles(pos, sld1, sld2))
      }
    end

    def calculate_volatiles(start, diff1, diff2) do
      mid_point = Coord.calculate_cprime(start, diff1)
      SMove.calculate_volatiles(start, diff1) ++
        SMove.calculate_volatiles(mid_point, diff2)
    end
  end

  defmodule Fill do
    defstruct ~w[nd volatiles]a

    def from_bot(%Bot{pos: pos}, nd) do
      %__MODULE__{
        nd: nd,
        volatiles: MapSet.new([pos, Coord.calculate_cprime(pos, nd)])
      }
    end
  end

  defmodule GFill do
    defstruct ~w[nd fd volatiles]a

    def from_bot(%Bot{pos: pos}, nd, fd) do
      %__MODULE__{
        nd: nd,
        fd: fd,
        volatiles: MapSet.new([pos | Coord.garea(pos, nd, fd)])
      }
    end
  end

  defmodule Void do
    defstruct ~w[nd volatiles]a

    def from_bot(%Bot{pos: pos}, nd) do
      %__MODULE__{
        nd: nd,
        volatiles: MapSet.new([pos, Coord.calculate_cprime(pos, nd)])
      }
    end
  end

  defmodule GVoid do
    defstruct ~w[nd fd volatiles]a

    def from_bot(%Bot{pos: pos}, nd, fd) do
      %__MODULE__{
        nd: nd,
        fd: fd,
        volatiles: MapSet.new([pos | Coord.garea(pos, nd, fd)])
      }
    end
  end

  defmodule Fission do
    defstruct ~w[nd m volatiles]a

    def from_bot(%Bot{pos: pos}, nd, m) do
      %__MODULE__{
        nd: nd,
        m: m,
        volatiles: MapSet.new([pos, Coord.calculate_cprime(pos, nd)])
      }
    end
  end

  defmodule FusionP do
    defstruct ~w[nd volatiles]a

    def from_bot(%Bot{pos: pos}, nd) do
      %__MODULE__{
        nd: nd,
        volatiles: MapSet.new([pos, Coord.calculate_cprime(pos, nd)])
      }
    end
  end

  defmodule FusionS do
    defstruct ~w[nd volatiles]a

    def from_bot(%Bot{ }, nd) do
      %__MODULE__{nd: nd, volatiles: MapSet.new}
    end
  end
end
