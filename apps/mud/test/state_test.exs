defmodule MUD.StateTest do
  use PowerAssert

  doctest MUD.State

  describe "character storage" do
    test "can create a player character" do
      assert MUD.State.player_exists?("Bob") == false

      MUD.State.add_player("Bob")

      assert MUD.State.player_exists?("Bob") == true
      
    end

    test "can retrieve a player character by name" do
      MUD.State.add_player("Alice")

      alice = MUD.State.get_player_by_name("Alice")
      assert alice.name == "Alice"
    end
  end
end
