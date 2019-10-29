# storage.ex
# Created by seve on Oct 23 2019
#
# This is part of the EffDB application.
#
# Copyright (c) 2019 tehprofessor - All Rights Reserved

defmodule EffDB.Storage do
  use DefContext
  defcontext [:storable, :transactable]

  alias EffDB.Table

  require Logger

  @type store() :: module()
  @type id() :: String.t() | pos_integer()
  @type record :: struct()
  @type database :: FDB.Database.t()

  @fdb_range_begin ""

 defmodule Storable do
    @moduledoc """
    A wrapper around `FDB.Database` to prevent the need for a live FDB
    process when testing by dynamically delegating to the given implementation.

    TODO:

      * [ ] This behaviour should be refined to not be so tightly coupled to `FDB.Database`
      * [ ] Should the be named `Adapter`?
    """

    alias FDB.KeySelectorRange
    alias FDB.Option

    @type t :: any()

    @callback set_defaults(cluster_db :: map, map) :: t

    @callback create() :: t
    @callback create(String.t()) :: t
    @callback create(String.t() | nil, map) :: t

    @callback set_option(t, Option.key()) :: :ok
    @callback set_option(t, Option.key(), Option.value()) :: :ok

    @callback get_range_stream(t, KeySelectorRange.t(), map) :: Enumerable.t()

    @callback transact(t, (Transactable.t() -> any)) :: any

    def set_defaults(storable, cluster_db, defaults) when is_map(defaults) do
      storable.set_defaults(cluster_db, defaults)
    end

    def create(storable, cluster_file_path \\ nil, defaults \\ %{}) when is_map(defaults) do
      storable.create(cluster_file_path, defaults)
    end

    def set_option(storable, database, option) do
      storable.set_option(database, option)
    end

    def set_option(storable, database, option, value) do
      storable.set_option(database, option, value)
    end

    def get_range_stream(storable, database, key_range, options \\ %{}) do
      storable.get_range_stream(database, key_range, options)
    end

    def transact(backend, database, callback) when is_function(callback) do
      backend.transact(database, callback)
    end
  end

  defmodule Keyspace do
    def root(nil), do: FDB.Directory.new()

    def root(override), do: override

    def create_or_open(root_dir \\ nil, transaction, path) do
      root(root_dir)
      |> FDB.Directory.create_or_open(transaction, path)
    end

    def list(directory, transaction) do
      FDB.Directory.list(directory, transaction)
    end
  end

  defmodule Transactable do
    @moduledoc """
    A wrapper around `FDB.Transaction` to prevent the need for a live FDB
    process when testing by dynamically delegating to the given implementation.

    TODO:

      * [ ] Decouple behaviour callbacks from `FDB.Transaction` for good times
    """

    alias FDB.{Database, Future, KeyRange, KeySelector, KeySelectorRange, Option, RangeResult}

    @type t :: %{resource: any, coder: any, snapshot: integer}

    @callback set_defaults(t, map) :: t
    @callback create(Storable.t(), map) :: t
    @callback set_option(t, Option.key()) :: :ok
    @callback set_option(t, Option.key(), Option.value()) :: :ok
    @callback get_range(t, KeySelectorRange.t(), map) :: RangeResult.t()
    @callback get_range_stream(t | Database.t(), KeySelectorRange.t(), map) :: Enumerable.t()
    @callback get_read_version(t) :: integer()
    @callback get_read_version_q(t) :: Future.t()
    @callback get_committed_version(t) :: integer()
    @callback get_versionstamp_q(t) :: Future.t()
    @callback watch_q(t, any) :: Future.t()
    @callback get(t, any, map) :: any
    @callback get_q(t, any, map) :: Future.t()
    @callback commit(t) :: :ok
    @callback commit_q(t) :: Future.t()
    @callback cancel(t) :: :ok
    @callback on_error(t, integer) :: :ok
    @callback on_error_q(t, integer) :: Future.t()
    @callback get_key(t, KeySelector.t()) :: any
    @callback get_key_q(t, KeySelector.t()) :: Future.t()
    @callback get_addresses_for_key(t, any) :: [String.t()]
    @callback get_addresses_for_key_q(t, any) :: Future.t()
    @callback set(t, any, any, map) :: :ok
    @callback set_read_version(t, integer) :: :ok
    @callback set_versionstamped_key(t, any, any, map) :: :ok
    @callback set_versionstamped_value(t, any, any, map) :: :ok
    @callback atomic_op(t, any, Option.key(), Option.value()) :: :ok
    @callback clear(t, any) :: :ok
    @callback clear_range(t, KeyRange.t()) :: :ok
    @callback add_conflict_range(t, KeyRange.t(), Option.key()) :: :ok
    @callback add_conflict_key(t, any(), Option.key()) :: :ok

    def commit(transactable, transaction) do
      transactable.commit(transaction)
    end

    def commit_q(transactable, transaction) do
      transactable.commit_q(transaction)
    end

    def get_range(transactable, transaction, key_selector_range, options \\ %{}) do
      transactable.get_range(transaction, key_selector_range, options)
    end

    def get_range_stream(transactable, transaction, key_selector_range, options \\ %{}) do
      transactable.get_range_stream(transaction, key_selector_range, options)
    end

    def get_read_version(transactable, transaction) do
      transactable.get_read_version(transaction)
    end

    def get_read_version_q(transactable, transaction) do
      transactable.get_read_version_q(transaction)
    end

    def cancel(transactable, transaction) do
      transactable.cancel(transaction)
    end

    def get_committed_version(transactable, transaction) do
      transactable.get_committed_version(transaction)
    end

    def get_versionstamp_q(transactable, transaction) do
      transactable.get_versionstamp_q(transaction)
    end

    def watch_q(transactable, transaction, key, options \\ %{}) do
      transactable.watch_q(transaction, key, options)
    end

    def get_key(transactable, transaction, key_selector, options \\ %{}) do
      transactable.get_key(transaction, key_selector, options)
    end

    def get_key_q(transactable, transaction, key_selector, options \\ %{}) do
      transactable.get_key_q(transaction, key_selector, options)
    end

    def get_addresses_for_key(transactable, transaction, key) do
      transactable.get_addresses_for_key(transaction, key)
    end

    def get_addresses_for_key_q(transactable, transaction, key, options \\ %{}) do
      transactable.get_addresses_for_key_q(transaction, key, options)
    end

    def set(transactable, transaction, key, value, options \\ %{}) do
      transactable.set(transaction, key, value, options)
    end

    def set_read_version(transactable, transaction, version) when is_integer(version) do
      transactable.set_read_version(transaction, version)
    end

    def set_versionstamped_key(transactable, transaction, key, value, options \\ %{}) do
      transactable.set_versionstamped_key(transaction, key, value, options)
    end

    def set_versionstamped_value(transactable, transaction, key, value, options \\ %{}) do
      transactable.set_versionstamped_value(transaction, key, value, options)
    end

    def atomic_op(transactable, transaction, key, operation_type, param, options \\ %{}) do
      transactable.atomic_op(transaction, key, operation_type, param, options)
    end

    def clear(transactable, transaction, key, options \\ %{}) do
      transactable.clear(transaction, key, options)
    end

    def clear_range(transactable, transaction, key_range, options \\ %{}) do
      transactable.clear_range(transaction, key_range, options)
    end

    def on_error(transactable, transaction, code) when is_integer(code) do
      transactable.on_error(transaction, code)
    end

    def on_error_q(transactable, transaction, code) when is_integer(code) do
      transactable.on_error_q(transaction, code)
    end

    def create(transactable, database, defaults \\ %{}) when is_map(defaults) do
      transactable.create(database, defaults)
    end

    def set_option(transactable, transaction, option) do
      transactable.set_option(transaction, option)
    end

    def set_option(transactable, transaction, option, value) do
      transactable.set_option(transaction, option, value)
    end

    def get(transactable, transaction, key, options \\ %{}) when is_map(options) do
      transactable.get(transaction, key, options)
    end

    def get_q(transactable, transaction, key, options \\ %{}) when is_map(options) do
      transactable.get_q(transaction, key, options)
    end

    def add_conflict_range(transactable, transaction, key_range, type, options \\ %{}) do
      transactable.add_conflict_range(transaction, key_range, type, options)
    end

    def add_conflict_key(transactable, transaction, key, type, options \\ %{}) do
      transactable.add_conflict_key(transaction, key, type, options)
    end
  end

  @doc """
  Creates the cluster_db which is what more or less initializes foundation,
  this calls `FDB.Database.create/1`.
  """
  @spec initialize_cluster_db(Context.t() | nil, String.t()) :: database()
  def initialize_cluster_db(context \\ nil, cluster_file)

  @spec initialize_cluster_db(nil, String.t()) :: database()
  def initialize_cluster_db(nil, cluster_file) do
    context = EffDB.Storage.Context.new()
    initialize_cluster_db(context, cluster_file)
  end

  @spec initialize_cluster_db(Context.t(), String.t()) :: database()
  def initialize_cluster_db(%{storable: storable}, cluster_file) do
    cluster_db = Storable.create(storable, cluster_file)
    Logger.debug("Initialized ClusterDB")

    cluster_db
  end

  @doc """
  Initializes a store (database) in foundation for the given table.
  """
  @spec initialize_store(Context.t() | nil, String.t()) :: database()
  def initialize_store(context \\ nil, cluster_db, table)

  @spec initialize_store(nil, String.t()) :: database()
  def initialize_store(nil, cluster_db, table) do
    context = EffDB.Storage.Context.new()

    initialize_store(context, cluster_db, table)
  end

  @spec initialize_store(Context.t(), String.t()) :: database()
  def initialize_store(%{storable: storable}, cluster_db, table) do
    db_coder = Table.table_coder(table)

    store = Storable.set_defaults(storable, cluster_db, %{coder: db_coder})
    store
  end

  @doc """
  Insert a record into it's store
  """
  @spec insert(Context.t() | nil, store, record) :: {:ok, EffDB.Table.Record.t()}
  def insert(context \\ nil, store, record)

  @spec insert(nil, store, record) :: {:ok, EffDB.Table.Record.t()}
  def insert(nil, store, record) do
    context = Context.new()
    insert(store, record, context)
  end

  @spec insert(Context.t(), store, record) :: {:ok, EffDB.Table.Record.t()}
  def insert(%{storable: storable, transactable: transactable}, store, record) do
    primary_key = Table.table_primary_key(record)
    encoded = Table.cast(record) |> Table.Record.to_tuple()

    result = Storable.transact(storable, store, fn transaction ->
      Transactable.set(transactable, transaction, primary_key, encoded)
    end)

    {result, record}
  end

  @doc """
  List all entries in the table, this could timeout...
  """
  @spec all(Context.t() | nil, store) :: [record]
  def all(context \\ nil, store)

  @spec all(nil, store) :: [record]
  def all(nil, store) do
    context = Context.new()
    all(context, store)
  end

  @spec all(Context.t(), store) :: [record]
  def all(%{storable: storable}, store) do
    all = FDB.KeySelectorRange.starts_with(@fdb_range_begin)

    Storable.get_range_stream(storable, store, all) |> Enum.to_list()
  end

  @doc """
  Using the default context, retrieve a record by id from the given store, or
  shit the bed...
  """
  @spec get(Context.t() | nil, store, id) :: record
  def get(context \\ nil, store, id)

  @spec get(nil, store, id) :: record()
  def get(nil, store, id) do
    context = Context.new()
    get(context, store, id)
  end

  @spec get(Context.t(), store, id) :: record
  def get(%{transactable: transactable}, store, id) do
    transaction = Transactable.create(transactable, store)
    record = Transactable.get(transactable, transaction, id)
    :ok = Transactable.commit(transactable, transaction)

    record
  end

  @doc """
  Using the default context, retrieve a record by id from the given store, or
  shit the bed...
  """
  @spec delete(Context.t() | nil, store, id) :: {:ok, record}
  def delete(context \\ nil, store, id)

  @spec delete(nil, store, id) :: {:ok, record}
  def delete(nil, store, id) do
    context = Context.new()
    delete(context, store, id)
  end

  @spec delete(Context.t(), store, id) :: {:ok, record}
  def delete(%{transactable: transactable, storable: storable}, store, id) do
    :ok = Storable.transact(storable, store, fn transaction ->
      _value = Transactable.get(transactable, transaction, id)
      Transactable.clear(transactable, transaction, id)
    end)

    {:ok, id}
  end
end