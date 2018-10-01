defmodule Server.TelnetTest do
  use PowerAssert

  doctest Server.Telnet

  describe "telnet middleware" do
    test "gets correct response to IAC" do
      {code, response} =
        Server.Telnet.handle_iac(
          nil,
          <<255, 251, 31, 255, 251, 32, 255, 251, 24, 255, 251, 39, 255, 253, 1, 255, 251, 3, 255,
            253, 3>>
        )

      assert code == :send

      assert response ==
               <<255, 253, 31, 255, 252, 32, 255, 252, 24, 255, 252, 39, 255, 251, 1, 255, 252, 3,
                 255, 254, 3>>

      {code, response} = Server.Telnet.handle_iac(nil, "Hello")
      assert code == :none
      assert response == nil
    end

    test "handles echo requests" do
      sid =
        Server.Session.create(:telnet, [
          &Server.Telnet.handle_iac/2,
          &Server.Telnet.handle_echo/2,
          &Server.Telnet.handle_negotiation/2
        ])

      {code, response} =
        Server.Telnet.handle_echo(
          sid,
          <<255, 251, 31, 255, 251, 32, 255, 251, 24, 255, 251, 39, 255, 253, 1, 255, 251, 3, 255,
            253, 3>>
        )

      assert code == :option
      assert response == {:echo, true}

      {code, response} = Server.Telnet.handle_echo(sid, <<255, 254, 1>>)
      assert code == :option
      assert response == {:echo, false}

      {code, response} = Server.Telnet.handle_echo(sid, <<255, 254, 31>>)
      assert code == :none
      assert response == nil

      Server.Session.update(sid, :opts, :echo, true)

      {code, response} = Server.Telnet.handle_echo(sid, "Hello")
      assert code == :send
      assert response == "Hello"
    end

    test "negotiates NAWS requests" do
      {code, response} =
        Server.Telnet.handle_negotiation(nil, <<255, 250, 31, 0, 80, 0, 24, 255, 240>>)

      assert code == :option
      assert response == {:window_size, {0, 80, 0, 24}}

      {code, response} = Server.Telnet.handle_negotiation(nil, <<255, 253, 1>>)
      assert code == :none
      assert response == nil

      {code, response} = Server.Telnet.handle_negotiation(nil, "Hello")
      assert code == :none
      assert response == nil
    end
  end
end
