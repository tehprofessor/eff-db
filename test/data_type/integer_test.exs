defmodule EffDB.DataType.IntegerTest do
  use ExUnit.Case
  alias EffDB.DataType.Integer, as: EffInteger
  alias FDB.Coder
  alias FDB.Coder.Integer

  describe "cast/1" do
    test "successfully casts integer" do
      assert {:ok, 3} = EffInteger.cast(3)
    end

    test "returns invalid_integer error for bad values" do
      assert {:error, {:invalid_integer, 4.0}} = EffInteger.cast(4.0)
      assert {:error, {:invalid_integer, "asdf"}} = EffInteger.cast("asdf")
      assert {:error, {:invalid_integer, %{}}} = EffInteger.cast(%{})
      assert {:error, {:invalid_integer, []}} = EffInteger.cast([])
      assert {:error, {:invalid_integer, _}} = EffInteger.cast(fn -> :weee end)
    end
  end

  describe "type/0" do
    test "return :integer" do
      assert EffInteger.type() == :integer
    end
  end

  describe "coder/1" do
    test "returns a FDB Integer" do
      assert %Coder{module: Integer} = EffInteger.coder()
    end
  end
end
