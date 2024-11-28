defmodule DroperGo.Amazon.Order.OrderFetcher do
  use GenServer
  alias DroperGo.Amazon.AmazonMarketplace

  @fetch_interval :timer.minutes(15)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    schedule_fetch()
    {:ok, state}
  end

  @impl true
  def handle_info(:fetch_orders, state) do
    orders = AmazonMarketplace.list_orders()

    process_orders(orders)

    schedule_fetch()
    {:noreply, state}
  end

  defp schedule_fetch do
    Process.send_after(self(), :fetch_orders, @fetch_interval)
  end

  defp process_orders(orders) do
    Enum.each(orders, fn order ->
      IO.inspect(order)
    end)
  end
end
