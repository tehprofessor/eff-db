defmodule EffDB.User do
  @behaviour EffDB.Schematic

  alias FDB.Transaction
  alias FDB.Coder.{ByteString, Integer, NestedTuple, Subspace, Tuple}

  defstruct [:id, :email, :password, :password_hash, :inserted_at, :updated_at, :__schema__]

  def table_name, do: "users"

  def table_indexes, do: [:id, :email]

  def email_index(transaction, %{id: id} = user) do
    existing = Transaction.get(transaction, user.email)
    case existing do
      nil ->
        :ok = Transaction.set(transaction, user.email, user.id)
        {:ok, :email_index_updated}
      ^id ->
        {:ok, :email_index_already_exists}
      error ->
        {:error, :email_must_be_unique}
    end
  end

  def table_fields do
    Tuple.new(
      {
        # Id
        ByteString.new(),
        # Email
        ByteString.new(),
        # Password Hash
        ByteString.new(),
        # Inserted At
        NestedTuple.new({
          # Year, Month, Date
          NestedTuple.new({Integer.new(), Integer.new(), Integer.new()}),
          # Hour, Minute, Second
          NestedTuple.new({Integer.new(), Integer.new(), Integer.new()})
        }),
        # Updated At
        NestedTuple.new({
          # Year, Month, Date
          NestedTuple.new({Integer.new(), Integer.new(), Integer.new()}),
          # Hour, Minute, Second
          NestedTuple.new({Integer.new(), Integer.new(), Integer.new()})
        })
      }
    )
  end

  def new(email, password) do
    id = UUID.uuid4()
    %__MODULE__{id: id, email: email, password: password}
  end
end

defimpl EffDB.Schema, for: EffDB.User do
  alias FDB.{Transaction}
  alias FDB.Coder.UUID, as: UUIDCoder

  def name(_schema), do: "users"

  def key(%{id: id}), do: "#{id}"

  def encode(%{password_hash: nil, password: password} = user) do
    encode(%{user | password_hash: Base.encode64(password)})
  end

  def encode(%{inserted_at: nil} = user) do
    current_time = DateTime.utc_now() |> NaiveDateTime.to_erl()
    encode(%{user | inserted_at: current_time})
  end

  def encode(%{updated_at: nil} = user) do
    current_time = DateTime.utc_now() |> NaiveDateTime.to_erl()
    encode(%{user | updated_at: current_time})
  end

  def encode(%{email: email, password_hash: password_hash, inserted_at: inserted_at, updated_at: updated_at} = user) do
    {EffDB.Schema.key(user), email, password_hash, inserted_at, updated_at}
  end

  def index_coder(%{__struct__: mod} = _user) do
    Transaction.Coder.new(
      EffDB.Schematic.index_for_table(mod)
    )
  end
end