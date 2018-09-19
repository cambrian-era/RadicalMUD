defmodule MUD do
  use Application

  @moduledoc """
  Documentation for MUD.
  """

  def start(_type, _args) do
    state = MUD.State.start_link([])
  end
end
