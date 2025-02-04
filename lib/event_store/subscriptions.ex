defmodule EventStore.Subscriptions do
  @moduledoc false

  alias EventStore.{Storage, Subscriptions}
  alias EventStore.Subscriptions.Subscription

  @all_stream "$all"

  def subscribe_to_stream(stream_uuid, subscription_name, subscriber, opts \\ [])

  def subscribe_to_stream(stream_uuid, subscription_name, subscriber, opts) do
    do_subscribe_to_stream(stream_uuid, subscription_name, subscriber, opts)
  end

  def subscribe_to_all_streams(subscription_name, subscriber, opts \\ [])

  def subscribe_to_all_streams(subscription_name, subscriber, opts) do
    do_subscribe_to_stream(@all_stream, subscription_name, subscriber, opts)
  end

  def unsubscribe_from_stream(stream_uuid, subscription_name) do
    do_unsubscribe_from_stream(stream_uuid, subscription_name)
  end

  def unsubscribe_from_all_streams(subscription_name) do
    do_unsubscribe_from_stream(@all_stream, subscription_name)
  end

  def delete_subscription(conn, stream_uuid, subscription_name, opts \\ []) do
    :ok = Subscriptions.Supervisor.shutdown_subscription(stream_uuid, subscription_name)

    Storage.delete_subscription(conn, stream_uuid, subscription_name, opts)
  end

  defp do_subscribe_to_stream(stream_uuid, subscription_name, subscriber, opts) do
    case Subscriptions.Supervisor.start_subscription(stream_uuid, subscription_name, opts) do
      {:ok, subscription} ->
        Subscription.connect(subscription, subscriber, opts)

      {:error, {:already_started, subscription}} ->
        case Keyword.get(opts, :concurrency_limit) do
          nil ->
            {:error, :subscription_already_exists}

          concurrency_limit when is_number(concurrency_limit) ->
            Subscription.connect(subscription, subscriber, opts)
        end
    end
  end

  defp do_unsubscribe_from_stream(stream_uuid, subscription_name) do
    Subscriptions.Supervisor.unsubscribe_from_stream(stream_uuid, subscription_name)
  end
end
