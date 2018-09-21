defmodule Server.SessionTest do
  use PowerAssert

  doctest Server.Session

  setup _context do
    {:ok, sessions} = Server.Session.start_link([])
    {:ok, [sessions: sessions]}
  end

  describe "session functions" do
    test "can create a new session" do
      id = Server.Session.create()

      [{_, data}, {_, time}] = new_session = Server.Session.get(id)

      assert Kernel.length(new_session) == 2
      assert data == ""
      assert time == 0
    end

    test "can update a session" do
      id = Server.Session.create()

      Server.Session.update(id, :data, "Hello")
      updated = Server.Session.get(id)
      
      assert updated[:data] == "Hello"

      Server.Session.update(id, :time, 1)
      update = Server.Session.get(id)

      assert update[:time] == 1
    end
  end
end