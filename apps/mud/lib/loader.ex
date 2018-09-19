defmodule MUD.Loader do
  require Poison
  require Logger

  @moduledoc """
  A general JSON loader
  """

  def load(path) do
    { result, file } = File.read(path)
    if result == :ok do
      Poison.decode(file)
    end
  end
end