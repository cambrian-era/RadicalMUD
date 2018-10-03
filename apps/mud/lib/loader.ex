defmodule MUD.Loader do
  require Poison
  require Logger

  @moduledoc """
  A general JSON loader
  """

  def load(path) do
    {result, file} = File.read(path)

    if result == :ok do
      Poison.decode(file)
    end
  end

  def load_manifest(path) do
    Logger.info("Loading manifest...")
    {:ok, manifest} = MUD.Loader.load(path)

    Enum.each(manifest["dungeons"], fn name ->
      Logger.info("Loading #{name}")
      dungeon_path = Path.join([Path.dirname(path), "dungeons", name, "dungeon.json"])

      if File.exists?(dungeon_path) do
        IO.inspect(load_dungeon(dungeon_path))
      else
        nil
      end
    end)
  end

  def load_dungeon(path) do
    {:ok, dungeon} = MUD.Loader.load(path)
    {:ok, rooms} = Path.dirname(path) |> Path.join("rooms.json") |> MUD.Loader.load()
    MUD.Dungeon.create(dungeon, rooms)
  end
end
