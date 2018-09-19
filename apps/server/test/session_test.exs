defmodule Server.SessionTest do
  use PowerAssert

  doctest Server.Session

  setup _context do
    {:ok, sessions} = Server.Session.start_link([])
    {:ok, [sessions: sessions]}
  end

  describe "session functions" do
    test "can create a new session", context do
      sessions = context[:sessions]

      id = Server.Session.create(sessions)

      [{_, data}, {_, time}] = new_session = Server.Session.get(sessions, id)

      assert Kernel.length(new_session) == 2
      assert data == ""
      assert time == 0
    end

    test "can update a session", context do
      sessions = context[:sessions]

      id = Server.Session.create(sessions)

      Server.Session.update(sessions, id, :data, "Hello")
      updated = Server.Session.get(sessions, id)
      
      assert updated[:data] == "Hello"

      Server.Session.update(sessions, id, :time, 1)
      update = Server.Session.get(sessions, id)

      assert update[:time] == 1
    end
  end
end