defmodule MUD.Dungeon do
  defstruct name: "",
            author: "",
            rooms: []

  def create(dungeon_data, rooms_data) do
    %MUD.Dungeon{
      name: dungeon_data["name"],
      author: dungeon_data["author"],
      rooms: Enum.map(rooms_data, &MUD.Room.create(&1))
    }
  end
end
