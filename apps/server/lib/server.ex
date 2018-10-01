defmodule RadServer do
  @moduledoc """
  Documentation for RadServer.
  """

  def start_link(:tcp, opts) do
    RadServer.Session.start_link([])

    :ranch.start_listener(
      :server,
      :ranch_tcp,
      [{:port, opts[:port]}],
      RadServer.Telnet,
      []
    )
  end
end
