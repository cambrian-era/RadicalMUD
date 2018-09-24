defmodule Server.Telnet do
  @behaviour :ranch_protocol

  # @cr <<13>>
  # @lf <<10>>

  @iac <<255>>

  @sub_begin <<250>>
  @sub_end <<240>>

  @term_type <<24>>

  def start_link(ref, socket, transport, _opts) do
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport])
    {:ok, pid}
  end

  def init(ref, socket, transport) do
    IO.puts("Starting Telnet")

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
        IO.puts("Closing connection - Normal")
        transport.close(socket)

      {:error, :timeout} ->
        IO.puts("Closing connection - Timeout")
        transport.close(socket)
    end
  end

  defp handle_data(<<255::size(8), data::binary>>, socket, transport) do
    data
    |> String.split(@iac)
    |> Enum.each(fn code ->
      case handle_response(code) do
        {:ok, response} ->
          transport.send(socket, response)

        {:error, response} ->
          IO.puts("Don't know how to handle this")
          IO.inspect(response)
      end
    end)

    server_handler(socket, transport)
  end

  defp handle_data(<<13, 10>>, socket, transport) do
    transport.send(socket, "Newline")
    server_handler(socket, transport)
  end

  defp handle_data(data, socket, transport) do
    IO.inspect(data)
    server_handler(socket, transport)
  end

  defp request_term_type(socket, transport) do
    transport.send(socket, <<@iac, 250, 24>>)
    server_handler(socket, transport)
  end

  defp handle_response(<<250::size(8), code::binary>>) do
    case code do
      # Get terminal type

      @term_type ->
        build :will, :term_type
      #   {:ok, <<@iac, @sub_begin, @term_type, 1, @iac, @sub_end>>}

      # Just deny anything else.
      _ ->
        IO.inspect(code)
        {:error, code}
    end
  end

  defp handle_response(<<250::size(8), code::binary>>) do
    IO.inspect(code)
    {:ok, @sub_end}
  end

  defp iac() do
    @iac
  end

  defp iac(bits) do
    bits <> @iac
  end

  defp sub_begin(bits) do
    bits <> @sub_begin
  end

  defp sub_end(bits) do
    bits <> @sub_end
  end

  # @will <<251>>
  # @wont <<252>>
  # @do_ <<253>>
  # @dont <<254>>

  defp build(command, option) do
    iac()
    |> sub_begin()
    |> option [@term_type, 1]
    |> iac()
    |> sub_end()
  end

  defp command(bits, command) do
    case command do
      :will ->
        bits <> <<251>>
      :wont ->
        bits <> <<252>>
      :do ->
        bits <> <<253>>
      :dont ->
        bits <> <<254>>
    end
  end

end