defmodule DroperGo.Amazom.AmazomMarketplace do
  use Tesla

  # Cliente Tesla com middlewares necessários
  plug Tesla.Middleware.BaseUrl, "https://sellingpartnerapi.amazon.com"
  plug Tesla.Middleware.Headers, [{"content-type", "application/json"}]
  plug Tesla.Middleware.JSON

  @refresh_token Application.compile_env(:your_app, :amazon_refresh_token)
  @client_id Application.compile_env(:your_app, :amazon_client_id)
  @client_secret Application.compile_env(:your_app, :amazon_client_secret)
  @marketplace_id Application.compile_env(:your_app, :amazon_marketplace_id)

  defmodule Order do
    @enforce_keys [:amazon_order_id, :purchase_date, :order_status]
    defstruct [
      :amazon_order_id,
      :purchase_date,
      :order_status,
      :last_update_date,
      :order_total,
      :shipping_address
    ]
  end

  def get_access_token do
    {:ok, response} =
      Tesla.post("https://api.amazon.com/auth/o2/token", %{
        grant_type: "refresh_token",
        refresh_token: @refresh_token,
        client_id: @client_id,
        client_secret: @client_secret
      })

    response.body["access_token"]
  end

  def list_orders(created_after \\ nil) do
    access_token = get_access_token()

    params = %{
      MarketplaceIds: @marketplace_id,
      CreatedAfter:
        created_after || DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.to_iso8601()
    }

    {:ok, response} =
      Tesla.get("/orders/v0/orders",
        headers: [{"Authorization", "Bearer #{access_token}"}],
        query: params
      )

    parse_orders(response.body)
  end

  defp parse_orders(%{"payload" => %{"Orders" => orders}}) do
    Enum.map(orders, fn order ->
      %Order{
        amazon_order_id: order["AmazonOrderId"],
        purchase_date: order["PurchaseDate"],
        order_status: order["OrderStatus"],
        last_update_date: order["LastUpdateDate"],
        order_total: parse_money(order["OrderTotal"]),
        shipping_address: parse_address(order["ShippingAddress"])
      }
    end)
  end

  defp parse_money(%{"Amount" => amount, "CurrencyCode" => currency}) do
    %{amount: Decimal.new(amount), currency: currency}
  end

  defp parse_address(nil), do: nil

  defp parse_address(address) do
    %{
      name: address["Name"],
      address_line1: address["AddressLine1"],
      address_line2: address["AddressLine2"],
      city: address["City"],
      state: address["StateOrRegion"],
      postal_code: address["PostalCode"],
      country_code: address["CountryCode"]
    }
  end
end
