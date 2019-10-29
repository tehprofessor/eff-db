defmodule EffDBTest do
  use ExUnit.Case
  doctest EffDB

  test "fuck yeah" do
    assert EffDB.fuck() == :yeah
  end
end
