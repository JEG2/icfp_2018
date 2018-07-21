defmodule Nanobots.StateTest do
  use ExUnit.Case
  alias Nanobots.{Bot, State, Model}
  alias Nanobots.Commands.{
    Halt, Wait, Flip, SMove, LMove, Fill, GFill, Void, GVoid, Fission, FusionP, FusionS
  }

  describe "applying commands to a state" do
    test "low harmonics increases state energy by 3 * r^3" do
      r = 4
      harmonics = :low
      state = %State{harmonics: harmonics, matrix: %Model{matrix: MapSet.new, resolution: r}}
      updated_state = State.apply(state, [%Wait{}])
      assert updated_state.energy == 3 * r * r * r
    end

    test "high harmonics increases state energy by 30 * r^3" do
      r = 4
      harmonics = :high
      state = %State{harmonics: harmonics, matrix: %Model{matrix: MapSet.new, resolution: r}}
      updated_state = State.apply(state, [%Wait{}])
      assert updated_state.energy == 30 * r * r * r
    end
  end

  describe "applying the Halt command" do
    test "removes last bot at {0,0,0}" do
      state = %State{}
      [bot] = state.bots
      State.apply_command(state, bot, %Halt{})
    end

    test "errors unless single bot in {0,0,0}" do
      state = %State{}
      [bot] = state.bots
      wrong_bot = %{bot | pos: {1,2,3}}
      assert_raise(FunctionClauseError, fn -> {
        State.apply_command(%{state | bots: [wrong_bot]}, bot, %Halt{})
      } end)
    end
  end

  describe "applying the Wait command" do
    test "returns the state unchanged" do
      state = %State{harmonics: :high, energy: 57}
      new_state = State.apply_command(state, List.first(state.bots), %Wait{})
      assert state == new_state
    end
  end

  describe "applying the Flip command" do
    test "flips the harmonics from low to high" do
      state = %State{harmonics: :low}
      new_state = State.apply_command(state, List.first(state.bots), %Flip{})
      assert new_state.harmonics == :high
    end

    test "flips the harmonics from high to low" do
      state = %State{harmonics: :high}
      new_state = State.apply_command(state, List.first(state.bots), %Flip{})
      assert new_state.harmonics == :low
    end
  end

  describe "applying the SMove command" do
    test "moves the bot" do
      bot = %Bot{pos: {8,15,17}}
      state = %State{bots: [bot]}
      new_state = State.apply_command(state, bot, %SMove{lld: {13,0,0}})
      assert List.first(new_state.bots).pos == {21,15,17}
    end

    test "updates the energy" do
      bot = %Bot{pos: {8,15,17}}
      state = %State{bots: [bot]}
      new_state = State.apply_command(state, bot, %SMove{lld: {13,0,0}})
      assert new_state.energy == state.energy + 26
    end
  end

  describe "applying the LMove command" do
    test "moves the bot" do
      bot = %Bot{pos: {8,15,17}}
      state = %State{bots: [bot]}
      new_state = State.apply_command(state, bot, %LMove{sld1: {4,0,0}, sld2: {0,0,3}})
      assert List.first(new_state.bots).pos == {12,15,20}
    end

    test "updates the energy" do
      bot = %Bot{pos: {8,15,17}}
      state = %State{bots: [bot]}
      new_state = State.apply_command(state, bot, %LMove{sld1: {4,0,0}, sld2: {0,0,3}})
      assert new_state.energy == state.energy + 18
    end
  end

  describe "applying the Fill command" do
    test "fills the voxel" do
      bot = %Bot{pos: {8,15,17}}
      state = %State{bots: [bot], matrix: %Model{matrix: MapSet.new}}
      new_state = State.apply_command(state, bot, %Fill{nd: {-1,-1,0}})
      MapSet.member?(new_state.matrix.matrix, {4,14,17})
    end

    test "updates the energy" do
      bot = %Bot{pos: {8,15,17}}
      state = %State{bots: [bot], matrix: %Model{matrix: MapSet.new}}
      new_state = State.apply_command(state, bot, %Fill{nd: {-1,-1,0}})
      assert new_state.energy == state.energy + 12
    end

    test "raises if already filled" do
      bot = %Bot{pos: {8,15,17}}
      state = %State{bots: [bot], matrix: %Model{matrix: MapSet.new([{7,14,17}])}}
      assert_raise(RuntimeError, "Already filled", fn -> {
        State.apply_command(state, bot, %Fill{nd: {-1,-1,0}})
      } end)
    end
  end

  describe "applying the GFill command" do
    test "fills the voxels" do
      bot = %Bot{pos: {8,15,17}}
      state = %State{bots: [bot], matrix: %Model{matrix: MapSet.new}}
      new_state = State.apply_command(state, bot, %GFill{nd: {1,0,0}, fd: {3,0,0}})
      assert new_state.matrix.matrix == MapSet.new([{9, 15, 17}, {10, 15, 17}, {11, 15, 17}])
    end

    test "updates the energy" do
      bot = %Bot{pos: {8,15,17}}
      energy = 17
      state = %State{bots: [bot], energy: energy, matrix: %Model{matrix: MapSet.new}}
      new_state = State.apply_command(state, bot, %GFill{nd: {1,0,0}, fd: {3,0,0}})
      assert new_state.energy == energy + (3 * 12)
    end

    test "updates the energy when one voxel is already filled" do
      bot = %Bot{pos: {8,15,17}}
      energy = 90
      state = %State{
        bots: [bot],
        energy: energy,
        matrix: %Model{
          matrix: MapSet.new([{9, 15, 17}])
        }
      }
      new_state = State.apply_command(state, bot, %GFill{nd: {1,0,0}, fd: {3,0,0}})
      assert new_state.energy == energy + (2 * 12) + (1 * 6)
    end
  end

  describe "applying the Void command" do
    test "voids the voxel" do
      bot = %Bot{pos: {8,15,17}}
      state = %State{bots: [bot], matrix: %Model{matrix: MapSet.new([{7,14,17}])}}
      new_state = State.apply_command(state, bot, %Void{nd: {-1,-1,0}})
      assert MapSet.member?(new_state.matrix.matrix, {4,14,17}) == false
    end

    test "updates the energy" do
      bot = %Bot{pos: {8,15,17}}
      state = %State{bots: [bot], matrix: %Model{matrix: MapSet.new([{7,14,17}])}}
      new_state = State.apply_command(state, bot, %Void{nd: {-1,-1,0}})
      assert new_state.energy == state.energy - 12
    end

    test "raises if already void" do
      bot = %Bot{pos: {8,15,17}}
      state = %State{bots: [bot], matrix: %Model{matrix: MapSet.new}}
      assert_raise(RuntimeError, "Already void", fn -> {
        State.apply_command(state, bot, %Void{nd: {-1,-1,0}})
      } end)
    end
  end

  describe "applying the GVoid command" do
    test "voids the voxels" do
      bot = %Bot{pos: {8,15,17}}
      state = %State{
        bots: [bot],
        matrix: %Model{
          matrix: MapSet.new([{9, 15, 17}, {10, 15, 17}, {11, 15, 17}])
        }
      }
      new_state = State.apply_command(state, bot, %GVoid{nd: {1,0,0}, fd: {3,0,0}})
      assert new_state.matrix.matrix == MapSet.new([])
    end

    test "updates the energy" do
      bot = %Bot{pos: {8,15,17}}
      energy = 90
      state = %State{
        bots: [bot],
        energy: energy,
        matrix: %Model{
          matrix: MapSet.new([{9, 15, 17}, {10, 15, 17}, {11, 15, 17}])
        }
      }
      new_state = State.apply_command(state, bot, %GVoid{nd: {1,0,0}, fd: {3,0,0}})
      assert new_state.energy == energy - (3 * 12)
    end

    test "updates the energy when one is already void" do
      bot = %Bot{pos: {8,15,17}}
      energy = 90
      state = %State{
        bots: [bot],
        energy: energy,
        matrix: %Model{
          matrix: MapSet.new([{9, 15, 17}, {10, 15, 17}])
        }
      }
      new_state = State.apply_command(state, bot, %GVoid{nd: {1,0,0}, fd: {3,0,0}})
      assert new_state.energy == energy - (2 * 12) + (1 * 3)
    end
  end

  describe "applying the Fission command" do
    test "creates the new bot with m seeds" do
      state = %State{}
      [bot] = state.bots
      nd = {1,0,0}
      m = 5
      new_state = State.apply_command(state, bot, %Fission{nd: nd, m: m})

      assert length(new_state.bots) == 2
      [bot1, bot2] = new_state.bots

      assert bot1.bid == 1
      assert bot1.pos == {0,0,0}
      assert bot1.seeds == [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]

      assert bot2.bid == 2
      assert bot2.pos == {1,0,0}
      assert bot2.seeds == [3, 4, 5, 6, 7]
    end

    test "updates the energy" do
      state = %State{}
      [bot] = state.bots
      nd = {1,0,0}
      m = 5
      new_state = State.apply_command(state, bot, %Fission{nd: nd, m: m})
      assert new_state.energy == state.energy + 24
    end
  end

  describe "applying the FusionP command" do
    test "removes the second bot" do
      state = %State{}
      [start_bot] = state.bots
      nd = {1,0,0}
      m = 5
      fission_state = State.apply_command(state, start_bot, %Fission{nd: nd, m: m})
      [fission_bot1, _fission_bot2] = fission_state.bots

      fusion_state = State.apply_command(fission_state, fission_bot1, %FusionP{nd: nd})
      [fusion_bot] = fusion_state.bots
      assert fusion_bot == start_bot
    end

    test "updates the energy" do
      state = %State{}
      [start_bot] = state.bots
      nd = {1,0,0}
      m = 5
      fission_state = State.apply_command(state, start_bot, %Fission{nd: nd, m: m})
      [fission_bot1, _fission_bot2] = fission_state.bots
      fusion_state = State.apply_command(fission_state, fission_bot1, %FusionP{nd: nd})

      assert fusion_state.energy == fission_state.energy - 24
    end
  end

  describe "applying the FusionS command" do
    test "is a noop command" do
      state = %State{}
      [start_bot] = state.bots
      nd = {1,0,0}
      m = 5
      fission_state = State.apply_command(state, start_bot, %Fission{nd: nd, m: m})
      [_fission_bot1, fission_bot2] = fission_state.bots
      fusion_state = State.apply_command(fission_state, fission_bot2, %FusionS{nd: nd})
      assert fusion_state == fission_state
    end
  end

  describe "end?" do
    test "true if there are no bots" do
      state = %State{bots: []}
      assert State.end?(state) == true
    end

    test "false if there are any bots" do
      state = %State{}
      assert State.end?(state) == false
    end
  end
end

