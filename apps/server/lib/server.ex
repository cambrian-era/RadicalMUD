defmodule Server do
  @moduledoc """
  Documentation for Server.
  """

  def start_link(:tcp, opts) do
    Server.Session.start_link([])

    :ranch.start_listener(
      :server,
      :ranch_tcp,
      [{:port, opts[:port]}],
      Server.Telnet,
      []
    )
  end
end
