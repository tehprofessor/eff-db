# metadata_table.ex
# Created by seve on Oct 27 2019
#
# This is part of the EffDB application.
#
# Copyright (c) 2019 tehprofessor - All Rights Reserved

defmodule EffDB.MetadataEntry do
  @moduledoc """
  Contains MetaData information regarding the current Stores (tables) and their indexes.

  """
  import EffDB.Table

  table(
    "meta_data_entries",
    position: :integer,
    name: :string,
    type: :string
  )
end

defmodule EffDB.MetadataTable do
  @moduledoc """
  Contains MetaData information regarding the current Stores (tables) and their indexes.

  A meta data table record containing an id set to the table's name.

  ## Ex.
      %EffDB.Table{id: "users"}
  """
  import EffDB.Table

  table(
    "meta_data_records",
    id: :string,
    version: :integer
  )
end

defmodule EffDB.MetaData do
  alias EffDB.MetadataTable
  alias EffDB.MetadataEntry
  alias EffDB.Storage.{Keyspace, Storable}

  use DefContext
  defcontext [:storable, :cluster_db]

  require Logger

  @type table :: EffDB.MetadataTable.t()
  @type entry :: EffDB.MetadataEntry.t()
  @type column_name_by_index :: {pos_integer(), String.t()}

  @effdb_metadata_path "effdb_metadata"

  @doc """
  Movie sucked, but this is a great name right here.
  """
  def inception(_context, _metadata) do

  end

  @doc """
  Fetch the last stored version of the given schema, from the meta data table,
  as a two-item tuple with `%MetadataTable{}` at position `0` and another tuple

  Ex.
      iex> last_stored_version_schema(context, %{id: "users", version: 0})
      {%MetadataTable{}, [{"0", "id"}, ... ]}
  """
  @spec last_stored_version_schema(Context.t(), MetadataTable.t()) :: [MetadataEntry.t()]
  def last_stored_version_schema(
        %{storable: storable, cluster_db: db} = _context,
        %{id: table_id, version: _} = _table_metadata
      ) do
    root = FDB.Directory.new()
    origin_path = [@effdb_metadata_path]
    path = [table_id]

    {newest_version, column_metadata_entries} = Storable.transact(storable, db, fn transaction ->
      # `origin_path` here is a single item list with: "effdb_metadata"
      origin_dir = Keyspace.create_or_open(root, transaction, origin_path)
      # Meow, create the table directory
      table_dir = Keyspace.create_or_open(origin_dir, transaction, path)
      # Next get all the versions we've stored
      newest_version = Keyspace.list(table_dir, transaction) |> List.last()
      # Open the current version
      version_dir = Keyspace.create_or_open(table_dir, transaction, newest_version)
      # The current version columns indexes
      column_indexes = Keyspace.list(version_dir, transaction)
      # Last stored version column names
      column_index_dirs = Enum.map(column_indexes, &{&1, Keyspace.create_or_open(version_dir, transaction, &1)})
      # Type for each column
      column_metadata_entries = for {index, column_index_dir} <- column_index_dirs do
        # The list should only contain one entry, the column name as a string.
        [column_name] = Keyspace.list(column_index_dir, transaction)
        # Now get the directory containing the column name.
        column_name_dir = Keyspace.create_or_open(column_index_dir, transaction, column_name)
        # The list should only contain one entry, the column type as a string.
        [column_type] = Keyspace.list(column_name_dir, transaction)
        # Profit
        %MetadataEntry{position: String.to_integer(index), name: column_name, type: column_type}
      end

      sorted_metadata_entries = Enum.sort(column_metadata_entries, &(&1.position <= &2.position))

      {newest_version, sorted_metadata_entries}
    end)

    last_stored_table = %MetadataTable{version: newest_version, id: table_id}

    {last_stored_table, column_metadata_entries}
  end

  def create(
        %{storable: storable, cluster_db: db} = _context,
        %{id: table_id, version: version} = _table_metadata,
        %{position: position, name: name, type: type} = _column_metadata) do
    root = FDB.Directory.new()
    origin_path = ["effdb_metadata"]
    path = [table_id, to_string(version), to_string(position), to_string(name), to_string(type)]

    Logger.debug("Creating Metadata for: #{table_id}, version: #{version}, path: #{path}")

    Storable.transact(storable, db, fn transaction ->
      table_keyspace = Keyspace.create_or_open(root, transaction, origin_path)
      Keyspace.create_or_open(table_keyspace, transaction, path)
    end)
  end

  def build_table_metadata(table_name, column_metadata) do
    metadata_table = %MetadataTable{id: table_name, version: "0"}
    metadata_columns = metadata_columns(column_metadata)

    {metadata_table, metadata_columns}
  end

  def build(tables, metadata \\ [])

  def build([table | tables], metadata) do
    table_name = table.table_name()
    number_of_columns = table.column_count() - 1
    column_metadata = Enum.map((number_of_columns..0), &table.column_metadata_at_index/1)

    {table, columns} = build_table_metadata(table_name, column_metadata)

    build(tables, [{table, columns} | metadata])
  end

  def build([], metadata) do
    metadata
  end

  def initialize_metadata(tables, _state) do
    _metadata = build(tables) |> validate() # |> write(state)
#    state = %{state | metadata: metadata}
#    EffDB.Storage.insert(state.storable, db, state)
  end

  defp validate(metadata) do
    metadata
  end

  @type column_metadata :: [MetadataEntry.t()]
  @type table_metadata :: {module, {MetadataTable.t(), column_metadata}}

  # Note: Use `cluster_db` it's the default `db` you're looking for...
  @spec write([table_metadata], map()) :: [table_metadata]
  def write([{_table, {_table_metadata, column_metadata}} | metadata], state) do
    root = FDB.Directory.new()
    table_name = column_metadata.id
    _table_dir = EffDB.Storage.Storable.transact(state.storable, state.cluster_db, fn transaction ->
      FDB.Directory.create_or_open(root, transaction, [table_name])
    end)

    metadata
  end

  def write([], state) do
    state
  end

  defp metadata_columns(columns, entries \\ [])

  defp metadata_columns([column | columns], entries) do
    {index, name, type} = column
    entry = %EffDB.MetadataEntry{position: index, name: name, type: type}

    metadata_columns(columns, [entry | entries])
  end

  defp metadata_columns([], entries) do
    entries
  end
end
