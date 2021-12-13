defmodule Phoenix.Presence.ClientTest do
  use ExUnit.Case, async: true

  alias Phoenix.Presence.Client.PresenceMock

  test "When a new process is tracked, a topic is created" do
    presence_key = 1
    topic_id = 100

    {:ok, pid} = PresenceMock.start_link(id: presence_key)

    PresenceMock.track(pid, topic(topic_id), presence_key)
    assert Process.alive?(pid)
    # _ = :sys.get_state(PresenceClient)
    :timer.sleep(1000)# not the best

    assert %{topics: %{"mock_topic:100" => %{"1" => [%{phx_ref: _ref}]}}} =
             GenServer.call(PresenceClient, :state)

    send(pid, :quit)
    :timer.sleep(1000)
    refute Process.alive?(pid)
  end

  test "topic is removed from the topics state when there is no more presences" do
    presence_key = 1
    topic_id = 100

    {:ok, pid} = PresenceMock.start_link(id: presence_key)

    PresenceMock.track(pid, topic(topic_id), presence_key)
    assert Process.alive?(pid)
    # _ = :sys.get_state(PresenceClient)

    :timer.sleep(1000)# not the best

    assert %{topics: %{"mock_topic:100" => %{"1" => [%{phx_ref: _ref}]}}} =
             GenServer.call(PresenceClient, :state)

    send(pid, :quit)
    :timer.sleep(1000)
    refute Process.alive?(pid)
    assert %{topics: %{}} = GenServer.call(PresenceClient, :state)
  end

  defp topic(id) do
    "mock_topic:#{id}"
  end
end
