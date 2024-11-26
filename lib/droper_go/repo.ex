defmodule DroperGo.Repo do
  use Ecto.Repo,
    otp_app: :droper_go,
    adapter: Ecto.Adapters.Postgres
end
