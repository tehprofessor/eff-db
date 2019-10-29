defmodule EffDB.TableTest.UserTable do
  @moduledoc """
  A module for testing the `EffDB.Table.table/2` macro.

  NOTE: This MUST to be placed BEFORE the TEST since we're using a protocol
  within the `table` macro.
  """

  @table_name "testing-table"

  import EffDB.Table

  table(
    @table_name,
    id: :string,
    email: :string,
    password: :virtual,
    password_hash: :string,
    fucks_given: :integer,
    inserted_at: :datetime,
    updated_at: :datetime
  )
end

defmodule EffDB.TableTest do
  use ExUnit.Case
  # Located at the bottom of this file
  alias EffDB.Table
  alias EffDB.TableTest.UserTable
  alias FDB.Coder
  alias Coder.{ByteString, Integer, NestedTuple, Subspace}

  @table_name "testing-table"
  # This is just a totally random UUID, but I prefer having a static value
  # to having a dependency in the tests on the UUID module...
  @uuid "07338869-df29-4bdc-902a-3740414a6168"

  test "cast/1" do
    assert %Table.Record{errors: _, values: _, table_name: @table_name} = Table.cast(%UserTable{})
  end

  test "table_primary_key/1" do
    assert Table.table_primary_key(%UserTable{id: @uuid}) == @uuid
  end

  test "table_name/1" do
    assert Table.table_name(%UserTable{}) == @table_name
  end

  test "table_coder/1" do
    assert %FDB.Transaction.Coder{key: %{module: Subspace}, value: _} = Table.table_coder(UserTable)
  end

  test "list_tables/0 - returns tables" do
    tables = Table.list_tables()
    Enum.each(tables, fn table ->
      assert :ok = Protocol.assert_impl!(EffDB.Table.TableTuple, table)
    end)
    # Ensure the meta data information is missing as they should not be user
    # modifiable.
    refute Enum.member?(tables, EffDB.MetadataTable)
    refute Enum.member?(tables, EffDB.MetadataEntry)
  end

  describe "table/1 - generated functions and behavior" do
    test "struct definition - correctly defines a struct with the keys" do
      assert %UserTable{id: nil, email: nil, password: nil, password_hash: nil, inserted_at: nil, updated_at: nil}
    end

    test "@after_compile - implements EffDB.Table.TableTuple" do
      assert :ok = Protocol.assert_impl!(EffDB.Table.TableTuple, UserTable)
    end

    test "column name functions - return correct coders" do
      # Generated functions from the column names with the correct types
      assert %Coder{module: ByteString} = UserTable.id()
      assert %Coder{module: ByteString} = UserTable.email()
      # Virtual attribute
      assert UserTable.password() == nil
      assert %Coder{module: ByteString} = UserTable.password_hash()
      assert %Coder{module: Integer} = UserTable.fucks_given()
      assert %Coder{module: NestedTuple} = UserTable.inserted_at()
      assert %Coder{module: NestedTuple} = UserTable.updated_at()
    end

    test "table_name/0 - returns the table name (#{@table_name})" do
      # Check if table_name has been created
      assert UserTable.table_name() == @table_name
    end

    test "primary_key/1 - returns the records primary key value" do
      # Check if table_name has been created
      assert UserTable.primary_key(%UserTable{id: @uuid}) == @uuid
    end

    test "table_tuple/0 - returns a correctly ordered table tuple"  do
      # Expected ordering of the tuple
      expected_table_tuple = [
        %Coder{module: ByteString},
        %Coder{module: ByteString},
        %Coder{module: ByteString},
        %Coder{module: Integer},
        %Coder{module: NestedTuple},
        %Coder{module: NestedTuple},
      ]

      actual_table_tuple = UserTable.table_tuple.opts

      # Ensure table tuple matches field coders at the correct index
      for {tuple, position} <- Enum.with_index(actual_table_tuple) do
        expected_type_at_position = Enum.at(expected_table_tuple, position)
        assert expected_type_at_position.module == tuple.module
        assert UserTable.field_coder_at_index(position).module == tuple.module
      end
    end

    test "column_count/0 - returns the correct count" do
      # Number of columns on the table, virtual fields are not included in this
      # count since they are not persisted.
      assert UserTable.column_count() == 6
    end

    test "cast/1 - returns a valid record without errors" do
      user_id = @uuid
      email = "turd.burgeson@example.com"
      hashed_password = Base.encode64("turds")
      inserted_at = DateTime.utc_now()
      updated_at = DateTime.utc_now()
      exactly_zero = 0

      user = %UserTable{
        id: user_id,
        email: email,
        password: "turds",
        password_hash: Base.encode64("turds"),
        fucks_given: exactly_zero,
        inserted_at: DateTime.to_iso8601(inserted_at),
        updated_at: DateTime.to_iso8601(updated_at)
      }

      inserted_at_tuple = NaiveDateTime.to_erl(inserted_at)
      updated_at_tuple = NaiveDateTime.to_erl(updated_at)

      # Expected values contains only values which will be persisted to
      # foundation db, virtual attribute values (like password) should be omitted.
      expected_values = [
        user_id,
        email,
        hashed_password,
        exactly_zero,
        inserted_at_tuple,
        updated_at_tuple
      ]

      expected_cast = %EffDB.Table.Record{
        errors: [],
        table_name: @table_name,
        values: expected_values
      }

      assert UserTable.cast(user) == expected_cast
    end

    test "cast/1 - returns a record with errors for an invalid record" do
      invalid_user = %UserTable{}
      # Fields that are NOT :nullable should throw an error if nil; so, in this
      # test case with an empty `%UserTable{}` all castable fields should be
      # present members of the error.
      expected_error_cast = %EffDB.Table.Record{
        errors: [
          id: {:invalid_string, nil},
          email: {:invalid_string, nil},
          password_hash: {:invalid_string, nil},
          fucks_given: {:invalid_integer, nil},
          inserted_at: {:invalid_datetime, nil},
          updated_at: {:invalid_datetime, nil}
        ],
        table_name: @table_name,
        values: []
      }

      assert UserTable.cast(invalid_user) == expected_error_cast
    end

    test "cast/1 - returns a record with errors & values for an invalid record" do
      email = "yetis.like.burritos@example.com"
      less_than_yesterday = -3
      invalid_user = %UserTable{id: @uuid, email: email, fucks_given: less_than_yesterday}
      # Fields that are NOT :nullable should return an error when cast
      expected_value_and_error_cast = %EffDB.Table.Record{
        errors: [
          password_hash: {:invalid_string, nil},
          inserted_at: {:invalid_datetime, nil},
          updated_at: {:invalid_datetime, nil}
        ],
        table_name: @table_name,
        values: [@uuid, email, less_than_yesterday]
      }

      assert UserTable.cast(invalid_user) == expected_value_and_error_cast
    end
  end
end
