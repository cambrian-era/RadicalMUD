defmodule MUD.State do
  use Agent

  @moduledoc """
  Provides access to the game's state.
  """

  @doc """
  Starts a new game state.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{players: []} end, [name: MUD.State])
  end

  @doc """
  Adds a new player to the current state with the
  given props. If the player does not exist, create
  them, otherwise load them.
  """
  def add_player(name) do
    player = MUD.Player.create(name)

    Agent.update(__MODULE__, fn state ->
      Map.put(state, :players, state[:players] ++ [player])
    end)
  end

  @doc """
  Returns true if a player with a given name exists in the current state.
  """
  def player_exists?(name) do
    Agent.get(__MODULE__, &Map.get(&1, :players))
    |> Enum.any?(&(&1.name == name))
  end

  @doc """
  Returns a player if that player exists, otherwise returns nil.
  """
  def get_player_by_name(name) do
    Agent.get(__MODULE__, &Map.get(&1, :players))
    |> Enum.find(&(&1.name == name))
  end
end