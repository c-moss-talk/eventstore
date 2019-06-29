defmodule EventStore.StorageCase do
  use ExUnit.CaseTemplate

  alias EventStore.Config
  alias EventStore.Storage

  setup_all do
    config = Config.parsed()
    postgrex_config = Config.default_postgrex_opts(config)

    {:ok, conn} = MyXQL.start_link(postgrex_config)

    [conn: conn]
  end

  setup %{conn: conn} do
    registry = Application.get_env(:eventstore, :registry, :local)

    Storage.Initializer.reset!(conn)

    after_reset(registry)

    on_exit(fn ->
      after_exit(registry)
    end)
  end

  defp after_exit(:local) do
    Application.stop(:eventstore)
  end

  defp after_exit(:distributed) do
    _ = :rpc.multicall(Application, :stop, [:eventstore])
  end

  defp after_reset(:local) do
    {:ok, _} = Application.ensure_all_started(:eventstore)
  end

  defp after_reset(:distributed) do
    _ = :rpc.multicall(Application, :ensure_all_started, [:eventstore])
  end
end
