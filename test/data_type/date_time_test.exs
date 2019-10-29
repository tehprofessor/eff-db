defmodule EffDB.DataType.DateTimeTest do
  use ExUnit.Case
  alias EffDB.DataType.DateTime, as: EffDateTime
  alias FDB.Coder
  alias FDB.Coder.{NestedTuple, Integer}

  describe "cast/1" do
    test "successfully casts an iso8601 string" do
      time = DateTime.utc_now()
      time_string = DateTime.to_iso8601(time)
      time_erl = NaiveDateTime.to_erl(time)

      assert EffDateTime.cast(time_string) == {:ok, time_erl}
    end

    test "successfully casts a DateTime struct" do
      time = DateTime.utc_now()
      time_erl = NaiveDateTime.to_erl(time)

      assert EffDateTime.cast(time) == {:ok, time_erl}
    end

    test "successfully casts a NaiveDateTime struct" do
      time = NaiveDateTime.utc_now()
      time_erl = NaiveDateTime.to_erl(time)

      assert EffDateTime.cast(time) == {:ok, time_erl}
    end

    test "returns an invalid_datetime_format error for an invalid string" do
      assert {:error, {:invalid_datetime_format, "cheese-it"}} = EffDateTime.cast("cheese-it")
    end

    test "returns an invalid_datetime error for bad values" do
      assert {:error, {:invalid_datetime, 4}} = EffDateTime.cast(4)
      assert {:error, {:invalid_datetime, 4.0}} = EffDateTime.cast(4.0)
      assert {:error, {:invalid_datetime, []}} = EffDateTime.cast([])
      assert {:error, {:invalid_datetime, _}} = EffDateTime.cast(fn -> :weee end)
      assert {:error, {:invalid_datetime, %{cheese: :it}}} = EffDateTime.cast(%{cheese: :it})
    end
  end

  describe "type/0" do
    test "return :string" do
      assert EffDateTime.type() == :datetime
    end
  end

  describe "coder/1" do
    test "returns a NestedTuple capable of holding the date and time" do
      coder = EffDateTime.coder()
      assert %Coder{module: NestedTuple} = coder

      for component <- coder.opts do
        assert %Coder{module: NestedTuple} = component

        for component_value <- component.opts do
          assert %Coder{module: Integer} = component_value
        end
      end
    end
  end
end
