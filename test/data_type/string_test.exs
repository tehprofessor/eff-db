defmodule EffDB.DataType.StringTest do
  use ExUnit.Case
  alias EffDB.DataType.String, as: EffString
  alias FDB.Coder
  alias FDB.Coder.ByteString

  describe "cast/1" do
    test "successfully casts string" do
      assert {:ok, "womp-womp"} = EffString.cast("womp-womp")
    end

    test "returns invalid_string error for bad values" do
      assert {:error, {:invalid_string, 3.0}} = EffString.cast(3.0)
      assert {:error, {:invalid_string, 4}} = EffString.cast(4)
      assert {:error, {:invalid_string, %{}}} = EffString.cast(%{})
      assert {:error, {:invalid_string, []}} = EffString.cast([])
      assert {:error, {:invalid_string, _}} = EffString.cast(fn -> :weee end)
    end
  end

  describe "type/0" do
    test "return :string" do
      assert EffString.type() == :string
    end
  end

  describe "coder/1" do
    test "returns a FDB ByteString" do
      assert %Coder{module: ByteString} = EffString.coder()
    end
  end
end
