defmodule EffDB.ConnectionManager do
  use GenServer

  alias EffDB.{Schema, Schematic}
  alias FDB.{Database, Transaction}

  defstruct [cluster_db: nil, databases: %{}]

  def get(schema, id) do
    GenServer.call(__MODULE__, {:get2, schema, id})
  end

  def insert(schema) do
    GenServer.call(__MODULE__, {:insert, schema})
  end

  def create_db(schema) do
    GenServer.cast(__MODULE__, {:create_db, schema})
  end

  def view_state(_schema) do
    GenServer.call(__MODULE__, :view_state)
  end

  def get_state(_schema) do
    GenServer.call(__MODULE__, :get_state)
  end
  # GenServer

  def start_link(cluster_file) do
    GenServer.start_link(__MODULE__, cluster_file, [name: __MODULE__])
  end

  def init(cluster_file) do
    db = Database.create(cluster_file)

    {:ok, %__MODULE__{cluster_db: db}}
  end

  def handle_call(:view_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:insert, schema}, _from, state) do
    key = Schema.key(schema)
    coded = Schema.encode(schema)
    db_module = module_for_schema(schema)
    db = Map.get(state.databases, db_module)

    Database.transact(db, fn tr ->
        IO.inspect([tr, key, coded], label: "transaction")
        Transaction.set(tr, key, coded)
    end)

    {:reply, :ok, state}
  end
  def handle_call({:get2, schema, id}, _from, state) do
    db_module = module_for_schema(schema)
    db = Map.get(state.databases, db_module)
    transaction = Transaction.create(db)
    value = Transaction.get(transaction, id)
    :ok = Transaction.commit(transaction)

    {:reply, value, state}
  end

  def handle_call({:get, schema, id}, _from, state) do
    db_module = module_for_schema(schema)
    db = Map.get(state.databases, db_module)
    record = Database.transact(db, fn transaction ->
      Transaction.get_key(transaction, id)
    end)

    {:reply, record, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:create_db, schema}, connection_manager) do
    {:noreply, add_db(connection_manager, schema)}
  end

  # Private

  defp add_db(%{cluster_db: cluster_db, databases: databases} = state, %_{} = schema) do
    db_module = module_for_schema(schema)
    db_coder = Schematic.table_coder(db_module)
    db = Database.set_defaults(cluster_db, %{coder: db_coder})

    databases = Map.put(databases, db_module, db)

    IO.inspect(db_coder, label: "cm->add_db :: coder")
    %{state | databases: databases}
  end

  def module_for_schema(%{__struct__: mod}), do: mod
end
