require Logger

alias FDB.{Database, Directory, Coder}
alias Coder.{Subspace, ByteString}

first_doc = EffDB.Document.new("First POST!", "life", "first-post", "## First\npost.\n")

db = EffDB.MetaDataServer.cluster_db()
metadata = EffDB.MetaDataServer.view_metadata()

root = FDB.Directory.new()
metadata_path = "effdb_metadata"
users_path = "users"
docs_path = "documents"

create_dir = fn
  (root,
  %{id: table_id, version: table_version} = table_metadata,
  %{position: position, name: name, type: type} = column) ->
  layer_name = [table_id, "layer"]
  origin_path = [metadata_path]
  path = [table_id, to_string(table_version), to_string(position), to_string(name), to_string(type)]

  Logger.info("Using path: #{inspect(path)}")

  FDB.Database.transact(db, fn transaction ->
    table_directory = FDB.Directory.create_or_open(root, transaction, origin_path)
    Logger.debug("creating-dir: #{inspect(path)}")
    FDB.Directory.create_or_open(table_directory, transaction, path)
  end)
end

insert_record = fn record, dir ->
  FDB.Database.transact(db, fn transaction ->
    FDB.Transaction.set(transaction, record.id, record.values)
  end)
end

print_directories = fn %{id: table_name, version: version} ->
  FDB.Database.transact(db, fn transaction ->
    origin_path = [table_name, to_string(version)]
    for sub_dir_1 <- FDB.Directory.list(root, transaction, origin_path) do
      sub_dir_1_path = origin_path ++ [sub_dir_1]
      for sub_dir_2 <- FDB.Directory.list(root, transaction, sub_dir_1_path) do
        final_path = sub_dir_1_path ++ [sub_dir_2]
      end
    end
  end)
end


fucking_root_dir = fn ->
  FDB.Database.transact(db, fn transaction ->
    FDB.Directory.list(root, transaction)
  end)
end

fucking_list_em = fn path ->
  FDB.Database.transact(db, fn transaction ->
    this_fucking_guy = FDB.Directory.create_or_open(root, transaction, path)
    these_fucking_guys = FDB.Directory.list(this_fucking_guy, transaction)
  end)
end

fuck_all_of_this = fn path ->
  destruction_happened = FDB.Database.transact(db, fn transaction ->
    FDB.Directory.remove(root, transaction, path)
  end)

  Logger.info("Said fuck it, and tried to balete: #{path}, result: #{destruction_happened}")
end

fucking_schema = for {table_metadata, columns} <- metadata, column_metadata <- columns do
  column_dir = create_dir.(root, table_metadata, column_metadata)
  Logger.debug("table: #{table_metadata.id} column_dir: #{inspect(column_dir.path)}")
  column_dir
end

fucking_fucks = for {table_metadata, columns} <- metadata do
  EffDB.MetaData.last_stored_version_schema(
    %{storable: FDB.Database, cluster_db: db},
    table_metadata
  ) |> IO.inspect(label: "#{table_metadata.id} version_schema")
end

fucking_tables = for {table_metadata, _} <- metadata do
  print_directories.(table_metadata)
end


{_metadata_dir, users_dir, docs_dir} = FDB.Database.transact(db, fn transaction ->
  metadata_dir = FDB.Directory.create_or_open(root, transaction, [metadata_path])
  users_dir = FDB.Directory.create_or_open(metadata_dir, transaction, [users_path])
  docs_dir = FDB.Directory.create_or_open(metadata_dir, transaction, [docs_path])
  {metadata_dir, users_dir, docs_dir}
end)
