defmodule EffDB.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    fdb_version = EffDB.Config.fdb_version()
    cluster_file = EffDB.Config.cluster_file()

    # This can only happen once, or it'll kill the application.
    :ok = start_fdb!(fdb_version)

    children = [
      {EffDB.MetaDataServer, {cluster_file, meta_data_server_context()}},
    ]

    opts = [strategy: :one_for_one, name: EffDB.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_fdb!(version) do
    :ok = FDB.start(version)
  end

  defp meta_data_server_context do
    %{storable: EffDB.Config.storable(), transactable: EffDB.Config.transactable()}
  end
end
