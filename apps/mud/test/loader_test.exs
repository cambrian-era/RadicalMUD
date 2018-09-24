defmodule MUD.LoaderTest do
  use PowerAssert

  require Logger

  doctest MUD.Loader

  test "it can load player data" do
    {result, data} = MUD.Loader.load(Path.join([__DIR__, "test_data/player.json"]))
    player = MUD.Player.load(data)

    assert result == :ok

    assert player.name == "Alice"
    assert player.level == 1
    assert MUD.Player.get_max(player, :hp) == 100
    assert MUD.Player.get_current(player, :sp) == 10
  end

  test "it can load manifests" do
    MUD.Loader.load_manifest(Path.join([__DIR__, "../lib/game_data/manifest.json"]))
  end
end
