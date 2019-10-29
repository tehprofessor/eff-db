defmodule EffDB.MetaDataServerTest do
  use ExUnit.Case
  alias EffDB.MetaDataServer
  alias EffDB.TestSupport.StorableMock

  describe "EffDB.MetaDataServer" do
    test "init/1" do
      cluster_db_path = "/eff/db"
      context = MetaDataServer.Context.new(%{storable: StorableMock})

      assert MetaDataServer.init({cluster_db_path, context}) ==
               {
                 :ok,
                 %MetaDataServer{
                   cluster_db: cluster_db_path,
                   storable: StorableMock
                 },
                 {:continue, nil}
               }
    end

    test "handle_continue/2" do
      tables = EffDB.Table.list_tables()

      assert {:noreply, %{stores: stores}} =
               MetaDataServer.handle_continue(nil, %{
                 cluster_db: "/eff/db",
                 stores: %{},
                 storable: StorableMock,
                 metadata: %{}
               })

      for {store_module, store_val} <- stores do
        assert Enum.member?(tables, store_module)
        assert store_val == %{set_defaults: %{}}
      end
    end
  end
end
