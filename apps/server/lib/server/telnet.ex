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

  @esc <<27, 91>>

  def start_link(ref, socket, transport, _opts) do
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport])
    {:ok, pid}
  end

  def init(ref, socket, transport) do
    Logger.info "Connected: #{:inet.peername(socket) |> elem(1) |> inspect()}"
    session_id = Server.Session.create(:telnet, [&__MODULE__.listen_state/4])

    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, false}, {:keepalive, true}])
    server_handler(session_id, socket, transport)
  end

  def server_handler(session_id, socket, transport) do
    response = transport.recv(socket, 0, 50000)

    session = Server.Session.get(session_id)

    case response do
      {:ok, data} ->
        session.state.(session_id, socket, transport, data)

      {:error, :closed} ->
        IO.puts("Closing connection - Normal: #{:inet.peername(socket) |> elem(1) |> inspect()}")
        transport.close(socket)

      {:error, :timeout} ->
        IO.puts("Closing connection - Timeout: #{:inet.peername(socket) |> elem(1) |> inspect()}")
        transport.close(socket)
    end
  end

  def listen_state(session_id, socket, transport, data) do
    case data do
      <<@cr, @lf>> ->
        transport.send(socket, Server.Session.get(session_id).data)
        Server.Session.update(session_id, :data, <<>>)

      <<255::size(8), _::binary>> ->
        transport.send(socket, build_response(session_id, data))
      _ ->
        if Server.Session.get(session_id)[:opts][:echo] do
          transport.send(socket, data)
        end
        Server.Session.update(
          session_id,
          :data,
          Server.Session.get(session_id).data <> data
        )
    end

    server_handler(session_id, socket, transport)
  end

  def build_response(session_id, data) do
    options = Server.Telnet.Options.options()
    Enum.map(String.split(data, @iac), fn (chunk) ->
      case chunk do
        <<251::size(8), code::binary>> ->
          response = options[code][:responses][@will]
          case response do
            nil ->
              nil
            _ ->
              case code do
                <<1>> ->
                  Server.Session.update(session_id, :opts, :echo, true)
                _ ->
                  nil
              end
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
          case code do
            <<1>> ->
              Server.Session.update(session_id, :opts, :echo, false)
            _ ->
              nil
          end
          @iac <> code <> options[code][:responses][@dont]
        _ ->
          nil
      end
    end)
    |> Enum.filter(&(&1 != nil))
    |> List.flatten()
    |> :binary.list_to_bin()
  end

  def execute_middleware(session_id, middleware, text) do
    Enum.each(middleware, fn (step) ->
      response = step.(session_id, text)
      if response != [] do
        Enum.each(response, fn (chunk) ->

        end)
      end
    end)
  end

  def handle_iac(session_id, text) do

  end

  def handle_negiotiation(session_id, text) do

  end

  def color(text) do
    regex = ~r/\[(\d+)(?:, )?(\d+)?\]\{([^\[]*)\}/

    Regex.replace(regex, text, fn _, fg, bg, text -> 
      out = @esc <> "38;5;" <> fg <> "m"
      out = if bg != "" do
        out <> @esc <> "48;5;" <> bg <> "m"
      else
        out
      end
      out <> text <> @esc <> "0m"
    end)
  end
end