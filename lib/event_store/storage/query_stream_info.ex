defmodule EventStore.Storage.QueryStreamInfo do
  @moduledoc false

  alias EventStore.Sql.Statements

  def execute(conn, stream_uuid, opts \\ []) do
    query = Statements.query_stream_id_and_latest_version()

    case MyXQL.query(conn, query, [stream_uuid], opts) do
      {:ok, %MyXQL.Result{num_rows: 0}} ->
        {:ok, nil, 0}

      {:ok, %MyXQL.Result{rows: [[stream_id, nil]]}} ->
        {:ok, stream_id, 0}

      {:ok, %MyXQL.Result{rows: [[stream_id, stream_version]]}} ->
        {:ok, stream_id, stream_version}
    end
  end
end
