# metadata_server.ex
# Created by seve on Oct 26 2019
#
# This is part of the EffDB application.
#
# Copyright (c) 2019 tehprofessor - All Rights Reserved

# TODO: Move a lot of this into persistent_term and only use server to write
# to persistent_term.

defmodule EffDB.MetaDataServer do
  @moduledoc """
  Responsible for managing tables and versioning them.
  It starts at boot, and will build, or migrate them sweet baby tables.
  """
  use DefContext
  defcontext [:storable, :transactable]

  use GenServer

  defstruct [cluster_db: nil, stores: %{}, metadata: %{}, storable: nil, transactable: nil]

  def start_link({cluster_file, context}, _opts \\ []) do
    GenServer.start_link(__MODULE__, {cluster_file, context}, [name: __MODULE__])
  end

  def init({cluster_file, %{storable: storable, transactable: transactable}}) do
    db = storable.create(cluster_file)

    {:ok, %__MODULE__{cluster_db: db, storable: storable, transactable: transactable}, {:continue, nil}}
  end

  @spec list_stores() :: list(map())
  def list_stores(), do: GenServer.call(__MODULE__, :list_stores)

  @spec view_metadata() :: list(map())
  def view_metadata(), do: GenServer.call(__MODULE__, :view_metadata)

  @spec cluster_db() :: list(map())
  def cluster_db(), do: GenServer.call(__MODULE__, :cluster_db)

  @spec insert(struct()) :: :ok
  def insert(record), do: GenServer.call(__MODULE__, {:insert, record})

  @spec get(module(), String.t()) :: :ok
  def get(table, id), do: GenServer.call(__MODULE__, {:get, table, id})

  @spec get(module(), String.t()) :: :ok
  def all(table), do: GenServer.call(__MODULE__, {:all, table})

  # Note: Thinking about the comment at the top of the file, this is probably
  # about all this should have. Anything else should be moved to the persistent
  # term using module.
  def handle_continue(_, state) do
    tables = EffDB.Table.list_tables()
    state = initialize_metadata!(tables, state)
    state = initialize_tables!(tables, state)

    {:noreply, state}
  end

  def handle_call(:list_stores, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:view_metadata, _from, %{metadata: metadata} = state) do
    {:reply, metadata, state}
  end

  def handle_call(:cluster_db, _from, %{cluster_db: cluster_db} = state) do
    {:reply, cluster_db, state}
  end

  def handle_call({:insert, record}, _from, state) do
    %{__struct__: table} = record
    store = Map.get(state.stores, table)
    result = EffDB.Storage.insert(store, record)

    {:reply, result, state}
  end

  def handle_call({:get, table, id}, _from, state) do
    store = Map.get(state.stores, table)
    result = EffDB.Storage.get(%{transactable: state.transactable}, store, id)

    {:reply, result, state}
  end

  def handle_call({:all, table}, _from, state) do
    store = Map.get(state.stores, table)
    result = EffDB.Storage.all(%{storable: state.storable}, store)

    {:reply, result, state}
  end

  defp initialize_metadata!(tables, state) do
    metadata = EffDB.MetaData.initialize_metadata(tables, state)
    %{state | metadata: metadata}
  end

  defp initialize_tables!([table | tables], state) do
    store = EffDB.Storage.initialize_store(%{storable: state.storable}, state.cluster_db, table)
    stores = Map.put(state.stores, table, store)

    initialize_tables!(tables, %{state | stores: stores})
  end

  defp initialize_tables!([], state) do
    state
  end
end
