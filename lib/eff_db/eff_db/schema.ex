defprotocol EffDB.Schema do
  @moduledoc false
  def encode(schema)
  def key(schema)
end

defmodule EffDB.Schematic do
  alias FDB.Coder.{ByteString, Subspace}
  @callback table_name() :: String.t()
  @callback table_fields() :: %FDB.Coder{}
  @callback table_indexes() :: [atom()]

  def new_subspace(name) do
    Subspace.new({name, ByteString.new()}, ByteString.new())
  end

  def index_for_table(table_subspace, key) do
    index_subspace = new_subspace(key)
    Subspace.concat(table_subspace, index_subspace)
  end

  def index_coder(mod) do
    table_subspace = new_subspace(mod.table_name())
    indexes = Enum.map(mod.table_indexes(), fn index_name ->
      index_subspace = index_for_table(table_subspace, index_name)
      index_coder = FDB.Transaction.Coder.new(index_subspace, ByteString.new())

      {index_name, index_coder}
    end)

    indexes
  end

  def table_coder(mod) do
    table_subspace = new_subspace(mod.table_name())
    table_tuple = mod.table_tuple()

    FDB.Transaction.Coder.new(table_subspace, table_tuple)
  end
end

defmodule EffDB.Schema.Id do
  def generate, do: UUID.uuid4()
end

defmodule EffDb.Schema.Index do

  defstruct [:row, :key, :schema]

  def new(row, key, schema) do
    %__MODULE__{row: row, key: key, schema: schema}
  end
end

defmodule EffDB.Constraint do
  alias FDB.Transaction

  def uniqueness(tr, key, _data) do
    if Transaction.get(tr, key) do
      {:error, {:not_unique_key, key}}
    else
      {:ok, nil}
    end
  end

#  defp perform_validation(tr, key, coded, [do: block]) when is_function(block) do
#    Transaction.get(tr, key)
#    |> block.(coded)
#  end
end
