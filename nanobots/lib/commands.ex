defmodule Commands do
  @moduledoc """
  Commands for Nanobots.
  """

  @doc """
  Commands a Nanobot to wait.
  """
  def wait(bot) do
    {:ok, %{
      bot: %{bot | command: :wait, metadata: %{}},
      volatile: [bot.pos],
      bot_added: nil,
      bot_removed: nil,
      fill: nil,
      flip: false,
      energy: 0
    }}
  end

  @doc """
  Commands a Nanobot to halt.
  """
  def halt(bot) do
    {:ok, %{
      bot: %{bot | command: :halt, metadata: %{}},
      volatile: [bot.pos],
      bot_added: nil,
      bot_removed: bot,
      fill: nil,
      flip: false,
      energy: 0
    }}
  end

  def flip(bot) do
    {:ok, %{
      bot: %{bot | command: :flip, metadata: %{}},
      volatile: [bot.pos],
      bot_added: nil,
      bot_removed: nil,
      fill: nil,
      flip: true,
      energy: 0
    }}
  end

  def s_move(bot, lld) do
    {:ok, %{
      bot: %{bot |
        pos: calculate_cprime(bot.pos, lld),
        command: :s_move,
        metadata: %{
          lld: lld
        }
      },
      volatile: calculate_volatile(bot.pos, lld),
      bot_added: nil,
      bot_removed: nil,
      fill: nil,
      flip: false,
      energy: 2 * mlen(lld)
    }}
  end

  def l_move(bot, sld1, sld2) do
    {:ok, %{bot: first_move_bot, volatile: first_move_volatile}} = s_move(bot, sld1)
    {:ok, %{bot: final_bot, volatile: [_ | second_move_volatile]}} = s_move(first_move_bot, sld2)
    {:ok, %{
      bot: %{final_bot |
        command: :l_move,
        metadata: %{
          sld1: sld1,
          sld2: sld2
        }
      },
      volatile: first_move_volatile ++ second_move_volatile,
      bot_added: nil,
      bot_removed: nil,
      fill: nil,
      flip: false,
      energy: 2 * (mlen(sld1) + 2 + mlen(sld2))
    }}
  end

  def fill(_bot, {0,0,0}) do
    {:error, "nd cannot be {0,0,0}"}
  end
  def fill(bot, nd = {nx, ny, 0}) when nx in [-1,0,1] and ny in [-1,0,1] do
    do_fill(bot, nd)
  end
  def fill(bot, nd = {nx, 0, nz}) when nx in [-1,0,1] and nz in [-1,0,1] do
    do_fill(bot, nd)
  end
  def fill(bot, nd = {0, ny, nz}) when ny in [-1,0,1] and nz in [-1,0,1] do
    do_fill(bot, nd)
  end

  defp do_fill(bot, nd) do
    filled = calculate_cprime(bot.pos, nd)
    {:ok, %{
      bot: %{bot | command: :fill, metadata: %{ nd: nd }},
      volatile: [bot.pos, filled],
      bot_added: nil,
      bot_removed: nil,
      fill: filled,
      flip: false,
      energy: 12 # or maybe 6 if it's already full but whatev
    }}
  end

  def fission(_bot, {0,0,0}, _m) do
    {:error, "nd cannot be {0,0,0}"}
  end
  def fission(bot, nd = {nx, ny, 0}, m) when nx in [-1,0,1] and ny in [-1,0,1] do
    do_fission(bot, nd, m)
  end
  def fission(bot, nd = {nx, 0, nz}, m) when nx in [-1,0,1] and nz in [-1,0,1] do
    do_fission(bot, nd, m)
  end
  def fission(bot, nd = {0, ny, nz}, m) when ny in [-1,0,1] and nz in [-1,0,1] do
    do_fission(bot, nd, m)
  end

  defp do_fission(bot, nd, m) when m >= 0 do
    new_bot_position = calculate_cprime(bot.pos, nd)
    [new_bot_id | new_bot_seeds] = Enum.take(bot.seeds, m + 1)
    new_bot = %{
      bid: new_bot_id,
      pos: new_bot_position,
      seeds: new_bot_seeds,
      command: :new_from_fission,
      metadata: %{}
    }
    {:ok, %{
      bot: %{bot |
        seeds: bot.seeds -- ([new_bot.bid] ++ new_bot.seeds),
        command: :fission,
        metadata: %{
          nd: nd,
          m: m
        }
      },
      volatile: [bot.pos, new_bot.pos],
      bot_added: new_bot,
      bot_removed: nil,
      fill: nil,
      flip: false,
      energy: 24
    }}
  end

  def fusion_p(bot1, bot2) do
    nd = coordinate_difference(bot1.pos, bot2.pos)
    :ok = case mlen(nd) do
      mlen when mlen in [1,2] -> :ok
      _ -> {:error}
    end
    {:ok, %{
      bot: %{bot1 |
        seeds: Enum.sort(bot1.seeds ++ ([bot2.bid] ++ bot2.seeds)),
        command: :fusion_p,
        metadata: %{
          nd: nd
        }
      },
      volatile: [bot1.pos, bot2.pos],
      bot_added: nil,
      bot_removed: bot2,
      fill: nil,
      flip: false,
      energy: -24
    }}
  end

  def fusion_s(bot1, bot2) do
    nd = coordinate_difference(bot1.pos, bot2.pos)
    :ok = case mlen(nd) do
      mlen when mlen in [1,2] -> :ok
      _ -> {:error}
    end
    {:ok, %{
      bot: %{bot1 |
        command: :fusion_s,
        metadata: %{
          nd: nd
        }
      },
      volatile: [bot1.pos, bot2.pos],
      bot_added: nil,
      bot_removed: nil,
      fill: nil,
      flip: false,
      energy: 0
    }}
  end

  def calculate_cprime({cx, cy, cz}, {dx, dy, dz}) do
    {cx + dx, cy + dy, cz + dz}
  end

  def mlen({x, y, z}) do
    abs(x) + abs(y) + abs(z)
  end

  def calculate_volatile(start, difference) do
    calculate_volatile(start, difference, [start])
  end
  def calculate_volatile(_, {0,0,0}, volatile) do
    volatile |> Enum.reverse
  end
  def calculate_volatile(start, {dx, 0, 0}, volatile) do
    next_step = calculate_cprime(start, {1, 0, 0})
    calculate_volatile(next_step, {dx-1, 0, 0}, [next_step | volatile])
  end
  def calculate_volatile(start, {0, dy, 0}, volatile) do
    next_step = calculate_cprime(start, {0, 1, 0})
    calculate_volatile(next_step, {0, dy-1, 0}, [next_step | volatile])
  end
  def calculate_volatile(start, {0, 0, dz}, volatile) do
    next_step = calculate_cprime(start, {0, 0, 1})
    calculate_volatile(next_step, {0, 0, dz-1}, [next_step | volatile])
  end

  def coordinate_difference({ax, ay, az}, {bx, by, bz}) do
    {bx - ax, by - ay, bz - az}
  end
end
