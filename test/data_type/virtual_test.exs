defmodule EffDB.DataType.VirtualTest do
  use ExUnit.Case
  alias EffDB.DataType.Virtual, as: EffVirtual

  describe "type/0" do
    test "return :float" do
      assert EffVirtual.type() == :virtual
    end
  end

  describe "coder/1" do
    test "returns nil, virtual attributes have no coder" do
      refute EffVirtual.coder()
    end
  end
end
