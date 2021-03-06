defmodule Server.SessionTest do
  use PowerAssert

  doctest Server.Session

  describe "session functions" do
    test "can create a new session" do
      id = Server.Session.create(:telnet, [fn x -> x end])

      %Server.Session.Telnet{} = new_session = Server.Session.get(id)

      assert new_session.data == <<>>
      assert new_session.time == 0
    end

    test "can update a session" do
      id = Server.Session.create(:telnet, fn x -> x end)

      Server.Session.update(id, :data, "Hello")
      updated = Server.Session.get(id)

      assert updated.data == "Hello"

      Server.Session.update(id, :time, 1)
      updated = Server.Session.get(id)

      assert updated.time == 1

      Server.Session.update(id, :opts, 'terminal_type', 'ANSI')
      updated = Server.Session.get(id)

      assert updated.opts['terminal_type'] == 'ANSI'
    end
  end
end
