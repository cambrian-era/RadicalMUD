defmodule Server.Telnet do
  @behaviour :ranch_protocol

  def start_link(ref, socket, transport, _opts) do
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport])
    {:ok, pid}
  end

  def init(ref, socket, transport) do
    IO.puts "Starting Telnet"

    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, false}])
    request_term_type(socket, transport)
    server_handler(socket, transport)
  end

  def server_handler(socket, transport) do
    response = transport.recv(socket, 0, 50000)
    
    case response do
      {:ok, data} ->
        handle_data(data, socket, transport)
      {:error, :closed} ->
        IO.puts "Closing connection - Normal"
        transport.close(socket)
      {:error, :timeout} ->
        IO.puts "Closing connection - Timeout"
        transport.close(socket)
    end
  end

  defp handle_data(<<255::size(8), data::binary>>, socket, transport) do
    data
    |> String.split(<<255>>)
    |> Enum.each(fn code ->
      case handle_response(code) do
        {:ok, response } ->
          transport.send(socket, response)
        {:error, response } ->
          IO.puts "Don't know how to handle this"
          IO.inspect response
      end
    end)
    server_handler(socket, transport)
  end

  defp handle_data(<<13, 10>>, socket, transport) do
    transport.send(socket, "Newline")
    server_handler(socket, transport)
  end

  defp handle_data(data, socket, transport) do
    IO.inspect data
    server_handler(socket, transport)
  end

  defp request_term_type(socket, transport) do
    transport.send(socket, <<255, 253, 24>>)
    server_handler(socket, transport)
  end

  # WILL  251 	Sender wants to do something.
  # WONT  252 	Sender doesn't want to do something.
  # DO    253 	Sender wants the other end to do something.
  # DONT  254 	Sender wants the other not to do something.
  defp handle_response(<<251::size(8), code::binary>>) do
    case code do
      <<24>> -> # Get terminal type
        {:ok, <<255, 250, 24, 1, 255, 240>>}
      _ -> # Just deny anything else.
        IO.inspect code
        {:error, code}
    end
  end

  defp handle_response(<<250::size(8), code::binary>>) do
    IO.inspect code
    {:ok, <<240>>}
  end
end