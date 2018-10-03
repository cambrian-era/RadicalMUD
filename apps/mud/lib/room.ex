defmodule MUD.Room do
  defstruct name: "",
            short_desc: "",
            long_desc: "",
            options: %{},
            exits: []

  def create(data) do
    r = Enum.map(data, fn {name, value} ->
      {String.to_atom(name), value}
    end)
    |> Map.new()
    |> Map.replace!(
      :options,
      Enum.map(data["options"], fn {name, value} ->
        {String.to_atom(name), value} 
      end)
    )
    |> Map.replace!(
      :exits,
      Enum.map(data["exits"], fn {name, value} ->
        {String.to_atom(name), value}
      end)
    )

    struct!(MUD.Room, r)
  end
end
