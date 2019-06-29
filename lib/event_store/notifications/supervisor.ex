defmodule EventStore.Notifications.Supervisor do
  @moduledoc false

  # Supervises the individual `GenStage` stages used to listen to and broadcast
  # all events appended to storage.
  #
  # Erlang's global module is used to ensure only a single instance of this
  # supervisor process, and its children including the PostgreSQL listener
  # process, runs on a cluster of nodes. This minimises connections to the event
  # store database. There will be at most one `LISTEN` connection per cluster.

  use Supervisor

  alias EventStore.{Config, MonitoredServer}
  alias EventStore.Notifications.{Listener, Reader, StreamBroadcaster}

  @doc """
  Starts a globally named supervisor process.

  This is to ensure only a single instance of the supervisor, and its
  supervised children, is kept running on a cluster of nodes.
  """
  def start_link(config) do
    case Supervisor.start_link(__MODULE__, config, name: {:global, __MODULE__}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, :killed} ->
        # Process may be killed due to `:global` name registation when another node connects.
        # Attempting to start again should link to the other named existing process.
        start_link(config)

      {:error, {:already_started, pid}} ->
        Process.link(pid)
        {:ok, pid}

      reply ->
        reply
    end
  end

  def init(config) do
    postgrex_config = Config.sync_connect_postgrex_opts(config)

    Supervisor.init(
      [
        Supervisor.child_spec(
          {MonitoredServer,
           [
             {MyXQL.Notifications, :start_link, [postgrex_config]},
             [
               name: Listener.MyXQL
             ]
           ]},
          id: Listener.MyXQL
        ),
        Supervisor.child_spec(
          {MonitoredServer,
           [
             {MyXQL, :start_link, [postgrex_config]},
             [name: Reader.MyXQL]
           ]},
          id: Reader.MyXQL
        ),
        {Listener, []},
        {Reader, Config.serializer()},
        {StreamBroadcaster, []}
      ],
      strategy: :one_for_all
    )
  end
end
