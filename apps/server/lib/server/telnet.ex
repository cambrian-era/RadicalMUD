defmodule Server.Telnet do
  @behaviour :ranch_protocol

  require Logger

  @iac <<255>>

  @esc <<27, 91>>

  def start_link(ref, socket, transport, _opts) do
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport])
    {:ok, pid}
  end

  def init(ref, socket, transport) do
    Logger.info("Connected: #{:inet.peername(socket) |> elem(1) |> inspect()}")

    sid =
      Server.Session.create(:telnet, [
        &__MODULE__.handle_iac/2,
        &__MODULE__.handle_echo/2,
        &__MODULE__.handle_negotiation/2
      ])

    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, false}, {:keepalive, true}])
    server_handler(sid, socket, transport)
  end

  def server_handler(sid, socket, transport) do
    response = transport.recv(socket, 0, 50000)

    session = Server.Session.get(sid)

    case response do
      {:ok, data} ->
        Server.Telnet.execute_middleware(sid, session.middleware, data, socket, transport)

      {:error, :closed} ->
        IO.puts("Closing connection - Normal: #{:inet.peername(socket) |> elem(1) |> inspect()}")
        transport.close(socket)

      {:error, :timeout} ->
        IO.puts("Closing connection - Timeout: #{:inet.peername(socket) |> elem(1) |> inspect()}")
        transport.close(socket)
    end
  end

  def execute_middleware(sid, middleware, data, socket, transport) do
    Enum.each(middleware, fn step ->
      {code, response} = step.(data)
      case code do
        :option ->
          Server.Session.update(Server.Session.get(sid), :opts, :echo, true)
        :send ->
          transport.send(socket, response)
      end
    end)
    server_handler(sid, socket, transport)
  end

  @doc """
  Handles IAC-prefixed commands, responding with the appropriate will/wont/do/dont signal
  """
  def handle_iac(_, <<255::size(8), data::binary>>) do
    chunks = String.split(data, @iac)

    responses =
      Enum.map(chunks, fn
        <<command::size(8), request::size(8)>> ->
          @iac <> Server.Telnet.Options.options()[<<request>>][:responses][<<command>>]

        _ ->
          nil
      end)
      |> Enum.filter(&(&1 != nil))

    {:send, responses}
  end

  def handle_iac(_, _) do
    {:none, nil}
  end

  @doc """
  Enables or disables echo if commanded, or echos the current data if enabled.
  """
  def handle_echo(_, <<255::size(8), data::binary>>) do
    chunks = String.split(data, @iac)

    case Enum.find(chunks, &(&1 == <<253, 1>> or &1 == <<254, 1>>)) do
      <<253, 1>> -> {:option, [{:echo, true}]}
      <<254, 1>> -> {:option, [{:echo, false}]}
      nil -> {:none, nil}
    end
  end

  def handle_echo(sid, data) do
    if Map.has_key?(Server.Session.get(sid).opts, :echo) and Server.Session.get(sid).opts[:echo] do
      {:send, data}
    else
      {:none, nil}
    end
  end

  @doc """
  Parses negotiation blocks
  """
  def handle_negotiation(sid, <<255::size(8), data::binary>>) do
    cond do
      data =~ <<31, 250>> ->
        {:option, nil}
      end
  end

  def color(text) do
    regex = ~r/\[(\d+)(?:, )?(\d+)?\]\{([^\[]*)\}/

    Regex.replace(regex, text, fn _, fg, bg, text ->
      out = @esc <> "38;5;" <> fg <> "m"

      out =
        if bg != "" do
          out <> @esc <> "48;5;" <> bg <> "m"
        else
          out
        end

      out <> text <> @esc <> "0m"
    end)
  end
end
