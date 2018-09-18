defmodule MUD.Player do
  defstruct name: "", id: "", level: 1

  @moduledoc """
  Defines the player structure and provides functions to work with it.
  """

  def create(name) do
    %MUD.Player{name: name, id: UUID.uuid1(), level: 1}
  end

  def load(_data) do
  end
end
