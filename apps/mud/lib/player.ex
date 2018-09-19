defmodule MUD.Player do
  require Logger
  defstruct name: "",
            id: "",
            level: 1,
            stats: %{
              hp: {100, 100},
              mp: {10, 100},
              sp: {10, 100},
              str: 10,
              agi: 10,
              int: 10,
              sta: 10
            },
            pronouns: %{
              subject: "they",
              object: "them",
              posessive: "their",
              reflexive: "themselves"
            }

  @moduledoc """
  Defines the player structure and provides functions to work with it.
  """

  def create(name) do
    %MUD.Player{name: name, id: UUID.uuid1(), level: 1}
  end

  def load(data) do
    %MUD.Player{
      name: data["name"],
      id: data["id"],
      level: data["level"],
      stats: Enum.map(data["stats"], fn stat ->
          { name, value } = stat
          if is_list(value) do
            {String.to_atom(name), List.to_tuple(value)}
          else
            {String.to_atom(name), value}
          end
        end) |> Map.new(),
      pronouns: data["pronouns"]
      }
  end

  @doc """
  Gets the player's maximum stat. Should be :hp, :mp, or :sp
  """
  def get_max(player, stat) do
    Map.get(player.stats, stat) |> elem(1)
  end

  @doc """
  Gets the player's current stat. Should be :hp, :mp, or :sp
  """
  def get_current(player, stat) do
    Map.get(player.stats, stat) |> elem(0)
  end
end
