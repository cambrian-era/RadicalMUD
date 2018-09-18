defmodule MUD.LoaderTest do
  use ExUnit.Case

  require Logger

  doctest MUD.Loader

  test "it can load player data" do
    { result, data } = MUD.Loader.load(Path.join([__DIR__, "test_data/player.json"]))
    player = MUD.Player.load(data)

    assert player.name == "Alice"
  end
end