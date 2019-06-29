defmodule EventStore.Storage.CreateStream do
  @moduledoc false

  require Logger

  alias EventStore.Sql.Statements

  def execute(conn, stream_uuid, opts \\ []) do
    _ = Logger.debug(fn -> "Attempting to create stream #{stream_uuid}" end)

    conn
    |> MyXQL.query(Statements.create_stream, [stream_uuid], opts)
    |> handle_create_response(stream_uuid)
  end

  defp handle_create_response({:ok, %MyXQL.Result{rows: [[stream_id]]}}, stream_uuid) do
    _ = Logger.debug(fn -> "Created stream #{inspect stream_uuid} (id: #{stream_id})" end)
    {:ok, stream_id}
  end

  defp handle_create_response({:error, %MyXQL.Error{mysql: %{code: :unique_violation}}}, stream_uuid) do
    _ = Logger.warn(fn -> "Failed to create stream #{inspect stream_uuid}, already exists" end)
    {:error, :stream_exists}
  end

  defp handle_create_response({:error, error}, stream_uuid) do
    _ = Logger.warn(fn -> "Failed to create stream #{inspect stream_uuid} due to: #{inspect error}" end)
    {:error, error}
  end
end
