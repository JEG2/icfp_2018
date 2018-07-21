defmodule CommandsTest do
  use ExUnit.Case
  doctest Commands

  @test_bot %{
    pos: {8, 15, 17},
    bid: 1,
    seeds: [2,3,4,5],
  }

  test "wait command waits" do
    {:ok, results} = Commands.wait(@test_bot)
    assert results == %{
      bot: @test_bot,
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
      bot: @test_bot,
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
      bot: @test_bot,
      volatile: [@test_bot.pos],
      bot_added: nil,
      bot_removed: nil,
      fill: nil,
      flip: true,
      energy: 0
    }
  end

  test "s_move does a move" do
    {:ok, results} = Commands.s_move(@test_bot, {13, 0, 0})
    assert results == %{
      bot: %{@test_bot | pos: {21, 15, 17}},
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
    {:ok, results} = Commands.l_move(@test_bot, {4, 0, 0}, {0,0,3})
    assert results == %{
      bot: %{@test_bot | pos: {12, 15, 20}},
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
    {:ok, results } = Commands.fill(@test_bot, {1,1,0})
    assert results == %{
      bot: @test_bot,
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
    {:ok, results } = Commands.fill(@test_bot, {1,0,1})
    assert results == %{
      bot: @test_bot,
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
    {:ok, results } = Commands.fill(@test_bot, {0,1,1})
    assert results == %{
      bot: @test_bot,
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
    {:ok, results } = Commands.fill(@test_bot, {-1,1,0})
    assert results == %{
      bot: @test_bot,
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
    {:ok, results} = Commands.fission(@test_bot, {0,-1,0}, 2)
    assert results == %{
      bot: %{@test_bot | seeds: [5]},
      bot_added: %{bid: 2, pos: {8, 14, 17}, seeds: [3, 4]},
      bot_removed: nil,
      energy: 24,
      fill: nil,
      flip: false,
      volatile: [@test_bot.pos, {8, 14, 17}]
    }
  end

  test "fusion removes bot2" do
    {:ok, results} = Commands.fission(@test_bot, {0,-1,0}, 2)
    test_bot_1 = results.bot
    test_bot_2 = results.bot_added
    {:ok, results} = Commands.fusion(test_bot_1, test_bot_2)
    assert results == %{
      bot: %{test_bot_1 | seeds: [2,3,4,5]},
      bot_added: nil,
      bot_removed: test_bot_2,
      energy: -24,
      fill: nil,
      flip: false,
      volatile: [test_bot_1.pos, test_bot_2.pos]
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
end
