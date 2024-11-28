defmodule DroperGo.Amazon.AmazonMarketplace do
  use Tesla

  alias DroperGo.Amazon.Myclient

  # Cliente Tesla com middlewares necessários
  plug Tesla.Middleware.BaseUrl, "https://sellingpartnerapi.amazon.com"
  plug Tesla.Middleware.Headers, [{"content-type", "application/json"}]
  plug Tesla.Middleware.JSON

  @refresh_token Application.compile_env(:droper_go, :amazon_refresh_token)
  @client_id Application.compile_env(:droper_go, :amazon_client_id)
  @client_secret Application.compile_env(:droper_go, :amazon_client_secret)
  @marketplace_id Application.compile_env(:droper_go, :amazon_marketplace_id)

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
    request_body = %{
      grant_type: "refresh_token",
      refresh_token: @refresh_token,
      client_id: @client_id,
      client_secret: @client_secret
    }

    case Myclient.post_data(
           "https://api.amazon.com/auth/o2/token",
           request_body
         ) do
      {:ok, response} ->
        IO.inspect(response)
        response.body["access_token"]

      {:error, reason} ->
        IO.inspect(reason)
    end
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

  def fetch_order_items(order_id) do
    case get_order_items(order_id) do
      {:error, message, _details} ->
        IO.puts("Erro: #{message}")

      items ->
        Enum.each(items, fn item ->
          IO.puts("""
          Produto: #{item.title}
          SKU: #{item.seller_sku}
          Quantidade: #{item.quantity_ordered}
          Preço: #{item.item_price} #{item.currency_code}
          """)
        end)
    end
  end

  def get_order_items(order_id) do
    case get("/orders/v0/orders/#{order_id}/orderItems") do
      {:ok, %{status: 200, body: body}} ->
        parse_order_items(body)

      {:ok, %{status: status, body: body}} ->
        {:error, "Erro na requisição. Status: #{status}", body}

      {:error, reason} ->
        {:error, "Falha na conexão", reason}
    end
  end

  defp parse_order_items(body) do
    items = body["payload"]["orderItems"]

    Enum.map(items, fn item ->
      %{
        asin: item["asin"],
        seller_sku: item["sellerSku"],
        title: item["title"],
        quantity_ordered: item["quantityOrdered"],
        item_price: item["itemPrice"]["amount"],
        currency_code: item["itemPrice"]["currencyCode"]
      }
    end)
  end
end

defmodule DroperGo.Amazon.Myclient do
  def client() do
    Tesla.client([
      {Tesla.Middleware.FormUrlencoded,
       encode: &Plug.Conn.Query.encode/1, decode: &Plug.Conn.Query.decode/1}
    ])
  end

  def post_data(url, params) do
    client()
    |> Tesla.post(url, params)
    |> IO.inspect()
  end
end
