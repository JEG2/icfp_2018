defmodule CommandsTest do
  use ExUnit.Case
  doctest Commands

  @test_bot %{
    pos: {8, 15, 17},
    bid: 1,
    seeds: [2,3,4,5],
    command: nil,
    metadata: nil
  }

  test "wait command waits" do
    {:ok, results} = Commands.wait(@test_bot)
    assert results == %{
      bot: %{@test_bot | command: :wait, metadata: %{}},
      volatile: [@test_bot.pos],
      bot_added: nil,
      bot_removed: nil,
      fill: nil,
      flip: false,
      energy: 0
    }
  end

  test "halt command halts" do
    {:ok, results} = Commands.halt(@test_bot)
    assert results == %{
      bot: %{@test_bot | command: :halt, metadata: %{}},
      volatile: [@test_bot.pos],
      bot_added: nil,
      bot_removed: @test_bot,
      fill: nil,
      flip: false,
      energy: 0
    }
  end

  test "flip command flips" do
    {:ok, results} = Commands.flip(@test_bot)
    assert results == %{
      bot: %{@test_bot | command: :flip, metadata: %{}},
      volatile: [@test_bot.pos],
      bot_added: nil,
      bot_removed: nil,
      fill: nil,
      flip: true,
      energy: 0
    }
  end

  test "s_move does a move" do
    {:ok, results} = Commands.s_move(@test_bot, lld = {13, 0, 0})
    assert results == %{
      bot: %{@test_bot |
        pos: {21, 15, 17},
        command: :s_move,
        metadata: %{lld: lld}
      },
      volatile: [
        @test_bot.pos,
        {9, 15, 17},
        {10, 15, 17},
        {11, 15, 17},
        {12, 15, 17},
        {13, 15, 17},
        {14, 15, 17},
        {15, 15, 17},
        {16, 15, 17},
        {17, 15, 17},
        {18, 15, 17},
        {19, 15, 17},
        {20, 15, 17},
        {21, 15, 17}
      ],
      bot_added: nil,
      bot_removed: nil,
      fill: nil,
      flip: false,
      energy: 26
    }
  end

  test "l move does a move" do
    {:ok, results} = Commands.l_move(@test_bot, sld1 = {4, 0, 0}, sld2 = {0,0,3})
    assert results == %{
      bot: %{@test_bot |
        pos: {12, 15, 20},
        command: :l_move,
        metadata: %{
          sld1: sld1,
          sld2: sld2
        }
      },
      volatile: [
        @test_bot.pos,
        {9, 15, 17},
        {10, 15, 17},
        {11, 15, 17},
        {12, 15, 17},
        {12, 15, 18},
        {12, 15, 19},
        {12, 15, 20},
      ],
      bot_added: nil,
      bot_removed: nil,
      fill: nil,
      flip: false,
      energy: 18
    }
  end

  test "fill {1,1,0}" do
    {:ok, results } = Commands.fill(@test_bot, nd = {1,1,0})
    assert results == %{
      bot: %{@test_bot | command: :fill, metadata: %{nd: nd}},
      volatile: [
        @test_bot.pos,
        {9,16,17}
      ],
      bot_added: nil,
      bot_removed: nil,
      fill: {9,16,17},
      flip: false,
      energy: 12
    }
  end

  test "fill {1,0,1}" do
    {:ok, results } = Commands.fill(@test_bot, nd = {1,0,1})
    assert results == %{
      bot: %{@test_bot | command: :fill, metadata: %{nd: nd}},
      volatile: [
        @test_bot.pos,
        {9,15,18}
      ],
      bot_added: nil,
      bot_removed: nil,
      fill: {9,15,18},
      flip: false,
      energy: 12
    }
  end

  test "fill {0,1,1}" do
    {:ok, results } = Commands.fill(@test_bot, nd = {0,1,1})
    assert results == %{
      bot: %{@test_bot | command: :fill, metadata: %{nd: nd}},
      volatile: [
        @test_bot.pos,
        {8,16,18}
      ],
      bot_added: nil,
      bot_removed: nil,
      fill: {8,16,18},
      flip: false,
      energy: 12
    }
  end

  test "fill {-1,1,0}" do
    {:ok, results } = Commands.fill(@test_bot, nd = {-1,1,0})
    assert results == %{
      bot: %{@test_bot | command: :fill, metadata: %{nd: nd}},
      volatile: [
        @test_bot.pos,
        {7,16,17}
      ],
      bot_added: nil,
      bot_removed: nil,
      fill: {7,16,17},
      flip: false,
      energy: 12
    }
  end

  test "fission creates a new bot with a bid and seeds" do
    {:ok, results} = Commands.fission(@test_bot, nd = {0,-1,0}, m = 2)
    assert results == %{
      bot: %{@test_bot |
        seeds: [5],
        command: :fission,
        metadata: %{
          nd: nd,
          m: m
        }
      },
      bot_added: %{
        bid: 2,
        pos: {8, 14, 17},
        seeds: [3, 4],
        command: :new_from_fission,
        metadata: %{}
      },
      bot_removed: nil,
      energy: 24,
      fill: nil,
      flip: false,
      volatile: [@test_bot.pos, {8, 14, 17}]
    }
  end

  test "fusion_p removes bot2" do
    {:ok, results} = Commands.fission(@test_bot, {0,-1,0}, 2)
    test_bot_1 = results.bot
    test_bot_2 = results.bot_added
    {:ok, results} = Commands.fusion_p(test_bot_1, test_bot_2)
    assert results == %{
      bot: %{test_bot_1 |
        seeds: [2,3,4,5],
        command: :fusion_p,
        metadata: %{
          nd: {0,-1,0}
        }
      },
      bot_added: nil,
      bot_removed: test_bot_2,
      energy: -24,
      fill: nil,
      flip: false,
      volatile: [test_bot_1.pos, test_bot_2.pos]
    }
  end

  # test "fusion_p rejects fusing bots that are too far apart" do
  #   {:ok, results} = Commands.fission(@test_bot, {0,-1,0}, 2)
  #   test_bot_1 = results.bot
  #   test_bot_2 = results.bot_added
  #   Commands.fusion_p(test_bot_1, %{test_bot_2 | pos: {200, 200, 200}})
  # end

  test "fusion_s" do
    {:ok, results} = Commands.fission(@test_bot, {0,-1,0}, 2)
    test_bot_1 = results.bot
    test_bot_2 = results.bot_added
    {:ok, results} = Commands.fusion_s(test_bot_2, test_bot_1)
    assert results == %{
      bot: %{test_bot_2 |
        command: :fusion_s,
        metadata: %{
          nd: {0,1,0}
        }
      },
      bot_added: nil,
      bot_removed: nil,
      energy: 0,
      fill: nil,
      flip: false,
      volatile: [test_bot_2.pos, test_bot_1.pos]
    }
  end

  test "manhattan length" do
    assert Commands.mlen({0,7,0}) == 7
    assert Commands.mlen({0,-7,0}) == 7
    assert Commands.mlen({1,2,3}) == 6
  end

  test "calculate c prime" do
    assert Commands.calculate_cprime({1,1,1}, {0,1,0}) == {1,2,1}
    assert Commands.calculate_cprime({1,1,1}, {1,2,3}) == {2,3,4}
    assert Commands.calculate_cprime({5,5,5}, {1,2,-3}) == {6,7,2}
  end

  test "calculate volatile" do
    volatile = Commands.calculate_volatile({0,0,0}, {0,5,0})
    assert volatile == [
      {0,0,0},
      {0,1,0},
      {0,2,0},
      {0,3,0},
      {0,4,0},
      {0,5,0},
    ]
  end

  test "coordinate_difference" do
    assert Commands.coordinate_difference({1,1,1}, {1,1,2}) == {0,0,1}
  end
end
