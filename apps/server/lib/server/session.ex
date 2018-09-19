defmodule Server.Session do
  @moduledoc """
  A simple session manager
  """

  use Agent

  require UUID

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  def create(sessions) do
    id = UUID.uuid4()
    Agent.get_and_update(sessions, fn state ->
      new_session = [data: "", time: 0]
      {state, Map.put(state, id, new_session)}
    end)

    id
  end

  def get(sessions, id) do
    Agent.get(sessions, &Map.get(&1, id))
  end

  def update(sessions, id, :data, data) do
    Agent.get_and_update(sessions, fn state ->
      m = Map.get(state, id) |> Keyword.update(:data, "", fn _ -> data end)
      {state, %{state | id => m}}
    end)
  end

  def update(sessions, id, :time, time) do
    Agent.get_and_update(sessions, fn state ->
      m = Map.get(state, id) |> Keyword.update(:time, 0, fn _ -> time end)
      {state, %{state | id => m}}
    end)
  end
end