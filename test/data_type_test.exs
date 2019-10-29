defmodule EffDB.DataTypeTest do
  use ExUnit.Case

  # The FDB aliases are used when testing the __using__  macro on the
  # `EffDB.DataType.String` module.
  alias FDB.Coder
  alias FDB.Coder.ByteString
  alias EffDB.DataType

  # Tests for the `using` macro need a module that _use_ it, and string will
  # likely be around forever so it should be safe to use here without having
  # to come back and edit this.
  #
  # This approach is convenient when a protocol is implemented within the
  # application, and it prevents those really irritating warnings about
  # redefining a module (like in table_test.exs).
  alias EffDB.DataType.String, as: EffString

  test "defines a struct" do
    assert %DataType{coder: nil, type: nil}
  end

  test "type/1" do
    assert DataType.type(:string) == EffString
    assert DataType.type(:integer) == DataType.Integer
    assert DataType.type(:float) == DataType.Float
    assert DataType.type(:datetime) == DataType.DateTime
    assert DataType.type(:virtual) == DataType.Virtual
    assert DataType.type(:uuid) == DataType.UUID
  end

  describe "__using__ - generated functions and behavior" do
    test "new/0 - returns %DataType{} with the module coder & data_type" do
      with %DataType{} = implemented <- EffString.new() do
        assert %Coder{module: ByteString, opts: {:bm, _}} = implemented.coder()
        assert :string = implemented.type()
      else
        incorrect_return_value ->
          flunked_message = """
          `__using__` failed to generate the correct new/1 function
            got: #{inspect(incorrect_return_value)}
            expected: %EffDB.DataType{}
          """

          flunk(flunked_message)
      end
    end
  end
end




