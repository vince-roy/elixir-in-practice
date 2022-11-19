defmodule One.Repo do
  use Ecto.Repo,
    otp_app: :one,
    adapter: Ecto.Adapters.Postgres
end
