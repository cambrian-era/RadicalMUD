defmodule Server.Telnet do
  alias Server.Session
  alias Server.Telnet.Options, as: Options
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
      Session.create(:telnet, [
        &__MODULE__.handle_iac/2,
        &__MODULE__.handle_echo/2,
        &__MODULE__.handle_negotiation/2
      ])

    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, false}, {:keepalive, true}])

    transport.send(socket, Server.Telnet.build_prompt({100, 100}, {20, 40}, {30, 69}, 80, 24))

    server_handler(sid, socket, transport)
  end

  def server_handler(sid, socket, transport) do
    response = transport.recv(socket, 0, 50000)

    session = Session.get(sid)

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

  @doc """
  Steps through the middleware and executes responses
  """
  def execute_middleware(sid, middleware, data, socket, transport) do
    Enum.each(middleware, fn step ->
      {code, response} = step.(sid, data)

      case code do
        :option ->
          {option, value} = response
          Session.update(sid, :opts, option, value)

        :send ->
          transport.send(socket, response)

        :none ->
          nil
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
          if Map.has_key?(Options.options(), <<request>>) do
            @iac <> Options.options()[<<request>>][:responses][<<command>>] <> <<request>>
          else
            @iac <> Options.options()[:else][:responses][<<command>>] <> <<request>>
          end

        _ ->
          nil
      end)
      |> Enum.filter(&(&1 != nil))
      |> List.flatten()
      |> :binary.list_to_bin()

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
      <<253, 1>> -> {:option, {:echo, true}}
      <<254, 1>> -> {:option, {:echo, false}}
      nil -> {:none, nil}
    end
  end

  def handle_echo(sid, data) do
    if Map.has_key?(Session.get(sid).opts, :echo) and Session.get(sid).opts[:echo] do
      {:send, data}
    else
      {:none, nil}
    end
  end

  @doc """
  Parses negotiation blocks
  """
  def handle_negotiation(_, <<255::size(8), data::binary>>) do
    cond do
      data =~ <<250, 31>> ->
        response =
          String.split(data, <<255>>)
          |> Enum.find_value(fn
            <<250::size(8), 31::size(8), x0::size(8), x1::size(8), y0::size(8), y1::size(8),
              _::binary>> ->
              {x0, x1, y0, y1}

            _ ->
              false
          end)

        {:option, {:window_size, response}}

      true ->
        {:none, nil}
    end
  end

  def handle_negotiation(_, _) do
    {:none, nil}
  end

  @doc """
  Parses color codes into escape codes.
  Colors are defined by using: [fg, bg]{text}
  Where fg and bg are valid ANSI color codes. fg is required, but bg is optional.
  """
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

  def build_prompt(hp, mp, sp, width, height) do
    stat = fn fg, bg, label, cur, max ->
      Server.Telnet.color("[#{fg}, #{bg}]{╫──#{label}─#{cur}/#{max}──╫}")
    end

    {cur_hp, max_hp} = hp
    {cur_mp, max_mp} = mp
    {cur_sp, max_sp} = sp

    stat_block =
      stat.(161, 233, "HP", cur_hp, max_hp) <>
        stat.(39, 233, "MP", cur_mp, max_mp) <> stat.(154, 233, "SP", cur_sp, max_sp)

    padding_size = width - 44 - 2

    @esc <> "#{height - 1}H" <> "├" <> stat_block <> Enum.reduce(0..padding_size, "─", fn _, p -> p <> "─" end) <> "┤"
  end
end