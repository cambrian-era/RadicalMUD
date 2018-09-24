defmodule Server.Telnet do
  @behaviour :ranch_protocol

  require Logger

  @cr <<13>>
  @lf <<10>>

  @iac <<255>>

  # @sub_begin <<250>>
  # @sub_end <<240>>

  # @term_type <<24>>

  def start_link(ref, socket, transport, _opts) do
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport])
    {:ok, pid}
  end

  def init(ref, socket, transport) do
    IO.puts("Starting Telnet connection")
    session_id = Server.Session.create(:telnet, &__MODULE__.listen_state/4)

    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, false}])
    # request_term_type(socket, transport)
    server_handler(session_id, socket, transport)
  end

  def server_handler(session_id, socket, transport) do
    response = transport.recv(socket, 0, 50000)

    session = Server.Session.get(session_id)

    case response do
      {:ok, data} ->
        session.state.(session_id, socket, transport, data)

      {:error, :closed} ->
        IO.puts("Closing connection - Normal")
        transport.close(socket)

      {:error, :timeout} ->
        IO.puts("Closing connection - Timeout")
        transport.close(socket)
    end
  end

  def listen_state(session_id, socket, transport, data) do
    case data do
      <<@cr, @lf>> ->
        transport.send(socket, Server.Session.get(session_id).data)
        Server.Session.update(session_id, :data, <<>>)

      <<255::size(8), _::binary>> ->
        
      _ ->
        transport.send(socket, data)
        Server.Session.update(
          session_id,
          :data,
          Server.Session.get(session_id).data <> data
        )
    end

    server_handler(session_id, socket, transport)
  end

  def build_response(data) do
    
  end

  def negotiate_begin_state(session_id, socket, transport) do
    server_handler(session_id, socket, transport)
  end

  def negotiate_listen_state(session_id, socket, transport) do
    server_handler(session_id, socket, transport)
  end

  def negotiate_end_state(session_id, socket, transport) do
    server_handler(session_id, socket, transport)
  end
end

# <<255, 251, 31, 255, 251, 32, 255, 251, 24, 255, 251, 39, 255, 253, 1, 255, 251, 3, 255, 253, 3>>