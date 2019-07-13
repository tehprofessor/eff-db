defmodule EffDB.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @fdb_version 610 # Currently max supported API version
  @cluster_file "/usr/local/etc/foundationdb/fdb.cluster"

  def start(_type, _args) do
    # This can only happen once, or it'll kill the application.
    :ok = start_fdb!(@fdb_version)

    children = [
      # Starts a worker by calling: EffDB.Worker.start_link(arg)
      # {EffDB.Worker, arg},
      {EffDB.ConnectionManager, [@cluster_file]},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EffDB.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_fdb!(version) do
    :ok = FDB.start(version)
  end
end
