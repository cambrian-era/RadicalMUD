defmodule RadServer.Session.Telnet do
  @enforce_keys [:id, :middleware]

  defstruct id: "",
            data: <<>>,
            time: 0,
            opts: %{},
            middleware: []

  @type t() :: %__MODULE__{
          id: String.t(),
          data: <<>>,
          time: number(),
          opts: Map.t(),
          middleware: [fun()]
        }

  def set_opt(session, key, value) do
    Map.replace!(session, :opts, Map.put(session.opts, key, value))
  end
end

defmodule RadServer.Session do
  use Agent

  @moduledoc """
  A simple session manager
  """
  require UUID

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: RadServer.Session)
  end

  @spec create(type :: atom(), middleware :: [fun()]) :: String.t()
  def create(:telnet, middleware) do
    session = %RadServer.Session.Telnet{
      id: UUID.uuid4(),
      data: <<>>,
      time: 0,
      middleware: middleware
    }

    Agent.update(__MODULE__, fn state ->
      Map.put(state, session.id, session)
    end)

    session.id
  end

  def get(id) do
    Agent.get(__MODULE__, &Map.get(&1, id))
  end

  def update(id, :data, data) do
    Agent.update(__MODULE__, fn state ->
      Map.replace!(state, id, Map.replace!(state[id], :data, data))
    end)
  end

  def update(id, :time, time) do
    Agent.update(__MODULE__, fn state ->
      Map.replace!(state, id, Map.replace!(state[id], :time, time))
    end)
  end

  def update(id, :opts, key, value) do
    Agent.update(__MODULE__, fn state ->
      Map.replace!(state, id, RadServer.Session.Telnet.set_opt(state[id], key, value))
    end)
  end
end
