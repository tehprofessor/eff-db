defmodule EffDB.MetaDataTest do
  @moduledoc """
  Tests for the `EffDB.MetaData` module.

  Note: A lot of asserts in this module would be obscene overkill, if it wasn't
  the fucking _database_. DATA IS LIFE. DATA MUST BE SACRED. DATA MUST BE SAFE!

  Note 2: Nothing about these tests guarantees a lack of catastrophic errors.
  The only way to ensure your shit is safe, is to: back. it. the. fuck. up.
  """
  use ExUnit.Case
  alias EffDB.MetaData

  describe "inception/1" do

  end

  describe "build/2" do
    test "returns successfully with metadata is sorted by position (ascending)" do
      [{metadata_table, metadata_columns}] = MetaData.build([EffDB.MetadataTable])
      assert metadata_table.id == EffDB.MetadataTable.table_name()

      column_count = EffDB.MetadataTable.column_count() - 1
      column_range = (0..column_count)

      # Make sure we are absolutely starting at 0.
      assert Enum.at(column_range, 0) == 0, """
      Column name indexing MUST start at 0 for this test. The for-comprehension
      tests using the `column_range` need to start from `0` to fucking ensure
      we're sorting by position (ascending).
      """

      Enum.each(column_range, fn expected_position ->
        metadata_column = Enum.at(metadata_columns, expected_position)
        assert metadata_column.position == expected_position, """
        Metadata columns are not sorted in ASCENDING order. This is required for
        checking equality during initialization of the `EffDB.MetaDataServer`,
        of the incoming MetaData and the last known MetaData.

           Found: #{metadata_column.position}, with #{inspect(metadata_column)}
        Expected: #{expected_position}
        """
      end)
    end
  end
end
