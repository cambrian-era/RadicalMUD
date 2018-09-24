defmodule Server.Session do
  use Agent

  @moduledoc """
  A simple session manager
  """
  require UUID

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: Server.Session)
  end

  def create() do
    id = UUID.uuid4()

    Agent.update(__MODULE__, fn state ->
      Map.put(state, id, data: "", time: 0)
    end)

    id
  end

  def get(id) do
    Agent.get(__MODULE__, &Map.get(&1, id))
  end

  def update(id, :data, data) do
    Agent.update(__MODULE__, fn state ->
      Map.replace!(state, id, Keyword.replace!(state[id], :data, data))
    end)
  end

  def update(id, :time, time) do
    Agent.update(__MODULE__, fn state ->
      Map.replace!(state, id, Keyword.replace!(state[id], :time, time))
    end)
  end
end
