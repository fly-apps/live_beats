defmodule Phoenix.Presence.ClientTest.Presence do
  use Phoenix.Presence,
    otp_app: :live_beats,
    pubsub_server: LiveBeats.PubSub
end

defmodule Phoenix.Presence.ClientTest do
  use ExUnit.Case

  alias Phoenix.Presence.Client.PresenceMock
  alias Phoenix.Presence.Client

  @pubsub LiveBeats.PubSub
  @client Phoenix.Presence.Client.Mock
  @presence Phoenix.Presence.ClientTest.Presence

  @presence_client_opts [client: @client, pubsub: @pubsub, presence: @presence]

  setup tags do
    start_supervised!({@presence, []})
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(LiveBeats.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    :ok
  end

  test "A topic key is added to the topics state when a new process is tracked" do
    presence_key = 1
    topic = topic(100)

    {:ok, presence_client} = start_supervised({Client, @presence_client_opts})
    {:ok, presence_process} = start_supervised({PresenceMock, id: presence_key})

    Phoenix.PubSub.subscribe(@pubsub, topic)
    Process.monitor(presence_process)

    PresenceMock.track(presence_client, presence_process, topic, presence_key)
    assert_receive %{event: "presence_diff"}

    client_state = :sys.get_state(presence_client)
    assert %{topics: %{^topic => %{"1" => [%{phx_ref: _ref}]}}} = client_state
  end

  test "topic is removed from the topics state when there is no more presences" do
    presence_key = 1
    topic = topic(100)

    {:ok, presence_client} = start_supervised({Client, @presence_client_opts})
    {:ok, presence_process} = start_supervised({PresenceMock, id: presence_key})

    Phoenix.PubSub.subscribe(@pubsub, topic)
    Process.monitor(presence_process)

    PresenceMock.track(presence_client, presence_process, topic, presence_key)
    assert Process.alive?(presence_process)
    assert_receive %{event: "presence_diff"}

    client_state = :sys.get_state(presence_client)
    assert %{topics: %{^topic => %{"1" => [%{phx_ref: _ref}]}}} = client_state

    send(presence_process, :quit)
    assert_receive {:DOWN, _ref, :process, ^presence_process, _reason}

    client_state = :sys.get_state(presence_client)
    assert %{topics: %{}} = client_state
  end

  test "metas are accumulated when there are two presences for the same key" do
    presence_key = 1
    topic = topic(100)

    {:ok, presence_client} = start_supervised({Client, @presence_client_opts})
    {:ok, presence_process_1} = start_supervised({PresenceMock, id: presence_key}, id: :mock_1)
    {:ok, presence_process_2} = start_supervised({PresenceMock, id: presence_key}, id: :mock_2)

    Phoenix.PubSub.subscribe(@pubsub, topic)

    PresenceMock.track(presence_client, presence_process_1, topic, presence_key, %{m1: :m1})
    assert_receive %{event: "presence_diff"}

    PresenceMock.track(presence_client, presence_process_2, topic, presence_key, %{m2: :m2})
    assert_receive %{event: "presence_diff"}

    client_state = :sys.get_state(presence_client)

    assert %{topics: %{^topic => %{"1" => [%{m1: :m1}, %{m2: :m2}]}}} = client_state
  end

  test "Just one meta is deleted when there are two presences for the same key and one leaves" do
    presence_key = 1
    topic = topic(100)

    {:ok, presence_client} = start_supervised({Client, @presence_client_opts})
    {:ok, presence_process_1} = start_supervised({PresenceMock, id: presence_key}, id: :mock_1)
    {:ok, presence_process_2} = start_supervised({PresenceMock, id: presence_key}, id: :mock_2)

    Phoenix.PubSub.subscribe(@pubsub, topic)
    Process.monitor(presence_process_1)

    PresenceMock.track(presence_client, presence_process_1, topic, presence_key, %{m1: :m1})
    assert_receive %{event: "presence_diff"}

    PresenceMock.track(presence_client, presence_process_2, topic, presence_key, %{m2: :m2})
    assert_receive %{event: "presence_diff"}

    client_state = :sys.get_state(presence_client)
    assert %{topics: %{^topic => %{"1" => [%{m1: :m1}, %{m2: :m2}]}}} = client_state

    send(presence_process_1, :quit)
    assert_receive {:DOWN, _ref, :process, ^presence_process_1, _reason}
    assert_receive %{event: "presence_diff"}

    client_state = :sys.get_state(presence_client)
    assert %{topics: %{^topic => %{"1" => [%{m2: :m2}]}}} = client_state
  end

  defp topic(id) do
    "mock_topic:#{id}"
  end
end
