defmodule Server.Telnet do
  @behaviour :ranch_protocol

  require Logger

  @cr <<13>>
  @lf <<10>>

  @iac <<255>>

  @will <<251>>
  @wont <<252>>
  @do_ <<253>>
  @dont <<254>>

  @sub_begin <<250>>
  @sub_end <<240>>

  def start_link(ref, socket, transport, _opts) do
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport])
    {:ok, pid}
  end

  def init(ref, socket, transport) do
    Logger.info "Starting Telnet connection"
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
        IO.inspect data
        transport.send(socket, build_response(data))
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
    options = Server.Telnet.Options.options()
    Enum.map(String.split(data, @iac), fn (chunk) ->
      case chunk do
        <<251::size(8), code::binary>> ->
          response = options[code][:responses][@will]
          case response do
            nil ->
              nil
            _ ->
              @iac <> response <> code
          end
        <<252::size(8), code::binary>> ->
          @iac <> code <> options[code][:responses][@wont]
        <<253::size(8), code::binary>> ->
          response = options[code][:responses][@do_]
          case response do
            nil ->
              nil
            _ ->
              @iac <> response <> code
          end
        <<254::size(8), code::binary>> ->
          @iac <> code <> options[code][:responses][@dont]
        _ ->
          nil
      end
    end)
    |> Enum.filter(&(&1 != nil))
    |> List.flatten()
    |> :binary.list_to_bin()
  end
end