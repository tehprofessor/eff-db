defmodule EffDB.DataType.FloatTest do

  use ExUnit.Case
  alias EffDB.DataType.Float, as: EffFloat
  alias FDB.Coder
  alias FDB.Coder.Float

  describe "cast/1" do
    test "successfully casts float" do
      assert {:ok, 3.0} = EffFloat.cast(3.0)
    end

    test "returns invalid_float error for bad values" do
      assert {:error, {:invalid_float, 4}} = EffFloat.cast(4)
      assert {:error, {:invalid_float, "asdf"}} = EffFloat.cast("asdf")
      assert {:error, {:invalid_float, %{}}} = EffFloat.cast(%{})
      assert {:error, {:invalid_float, []}} = EffFloat.cast([])
      assert {:error, {:invalid_float, _}} = EffFloat.cast(fn -> :weee end)
    end
  end

  describe "type/0" do
    test "return :float" do
      assert EffFloat.type() == :float
    end
  end

  describe "coder/1" do
    test "returns a FDB float" do
      assert %Coder{module: Float} = EffFloat.coder()
    end
  end
end
