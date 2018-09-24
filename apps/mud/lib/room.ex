defmodule MUD.Room do
  defstruct name: "",
            short_desc: "",
            long_desc: "",
            options: %{},
            exits: []
end
