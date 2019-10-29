defmodule EffDB.DataType.UUIDTest do
  use ExUnit.Case

  alias EffDB.DataType.UUID, as: EffUUID
  alias FDB.Coder.UUID, as: CoderUUID

  describe "type/0" do
    test "successfully casts valid uuid from string" do
      uuid = UUID.uuid4()
      assert EffUUID.cast(uuid) == {:ok, uuid}
    end

    test "returns an invalid_uuid_format error for an invalid string" do
      assert {:error, {:invalid_uuid_format, "cheese-it"}} = EffUUID.cast("cheese-it")
    end

    test "returns an invalid_uuid error for bad values" do
      assert {:error, {:invalid_uuid, 4}} = EffUUID.cast(4)
      assert {:error, {:invalid_uuid, 4.0}} = EffUUID.cast(4.0)
      assert {:error, {:invalid_uuid, []}} = EffUUID.cast([])
      assert {:error, {:invalid_uuid, _}} = EffUUID.cast(fn -> :weee end)
      assert {:error, {:invalid_uuid, %{cheese: :it}}} = EffUUID.cast(%{cheese: :it})
    end
  end

  describe "cast/1" do
    test "returns FDB.Coder.UUID" do
      assert EffUUID.coder() == CoderUUID.new()
    end
  end

  describe "coder/0" do
    test "returns FDB.Coder.UUID" do
      assert EffUUID.coder() == CoderUUID.new()
    end
  end
end
