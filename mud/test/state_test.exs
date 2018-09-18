defmodule MUD.StateTest do
  use ExUnit.Case

  doctest MUD.State

  setup _context do
    {:ok, state} = MUD.State.start_link([])
    {:ok, [state: state]}
  end

  describe "character storage" do
    test "can create a player character", context do
      state = context[:state]

      assert MUD.State.player_exists?(state, "Bob") == false

      MUD.State.add_player(state, %{name: "Bob"})

      assert MUD.State.player_exists?(state, "Bob") == true
    end

    test "can retrieve a player character by name", context do
      state = context[:state]

      assert MUD.State.get_player_by_name(state, "Bob") == nil

      MUD.State.add_player(state, %{name: "Bob"})

      assert MUD.State.get_player_by_name(state, "Bob").name == "Bob"
    end
  end
end
