defmodule Server.TelnetTest do
  use PowerAssert

  doctest Server.Telnet

  describe "telnet middleware" do
    test "gets correct response to IAC" do
      {code, response} = Server.Telnet.handle_iac(nil, <<255, 253, 1>>)
      assert code == :send
      assert response == [<<255, 251, 1>>]

      {code, response} = Server.Telnet.handle_iac(nil, "Hello")
      assert code == :none
      assert response == nil
    end

    test "handles echo requests" do
      sid = Server.Session.create(:telnet, [
        &Server.Telnet.handle_iac/2,
        &Server.Telnet.handle_echo/2,
        &Server.Telnet.handle_negotiation/2
      ])

      {code, response} = Server.Telnet.handle_echo(sid, <<255, 253, 1>>)
      assert code == :option
      assert response == [{:echo, true}]

      {code, response} = Server.Telnet.handle_echo(sid, <<255, 254, 1>>)
      assert code == :option
      assert response == [{:echo, false}]

      {code, response} = Server.Telnet.handle_echo(sid, <<255, 254, 31>>)
      assert code == :none
      assert response == nil

      Server.Session.update(sid, :opts, :echo, true)

      {code, response} = Server.Telnet.handle_echo(sid, "Hello")
      assert code == :send
      assert response == "Hello"
    end
  end
end
