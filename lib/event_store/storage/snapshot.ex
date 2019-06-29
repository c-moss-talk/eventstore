defmodule EventStore.Storage.Snapshot do
  @moduledoc false

  require Logger

  alias EventStore.Snapshots.SnapshotData
  alias EventStore.Sql.Statements

  def read_snapshot(conn, source_uuid, opts \\ []) do
    case MyXQL.query(conn, Statements.query_get_snapshot(), [source_uuid], opts) do
      {:ok, %MyXQL.Result{num_rows: 0}} ->
        {:error, :snapshot_not_found}

      {:ok, %MyXQL.Result{rows: [row]}} ->
        {:ok, to_snapshot_from_row(row)}

      {:error, error} = reply ->
        Logger.warn(fn ->
          "Failed to read snapshot for source \"#{source_uuid}\" due to: #{inspect(error)}"
        end)

        reply
    end
  end

  def record_snapshot(conn, %SnapshotData{} = snapshot, opts \\ []) do
    %SnapshotData{
      source_uuid: source_uuid,
      source_version: source_version,
      source_type: source_type,
      data: data,
      metadata: metadata
    } = snapshot

    params = [source_uuid, source_version, source_type, data, metadata]

    case MyXQL.query(conn, Statements.record_snapshot(), params, opts) do
      {:ok, _result} ->
        :ok

      {:error, error} = reply ->
        Logger.warn(fn ->
          "Failed to record snapshot for source \"#{source_uuid}\" at version \"#{source_version}\" due to: #{
            inspect(error)
          }"
        end)

        reply
    end
  end

  def delete_snapshot(conn, source_uuid, opts \\ []) do
    case MyXQL.query(conn, Statements.delete_snapshot(), [source_uuid], opts) do
      {:ok, _result} ->
        :ok

      {:error, error} = reply ->
        Logger.warn(fn ->
          "Failed to delete snapshot for source \"#{source_uuid}\" due to: #{inspect(error)}"
        end)

        reply
    end
  end

  defp to_snapshot_from_row([source_uuid, source_version, source_type, data, metadata, created_at]) do
    %SnapshotData{
      source_uuid: source_uuid,
      source_version: source_version,
      source_type: source_type,
      data: data,
      metadata: metadata,
      created_at: created_at
    }
  end
end
