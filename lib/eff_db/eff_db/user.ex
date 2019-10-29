# user.ex
# Created by seve on Oct 22 2019
#
# This is part of the EffDB application.
#
# Copyright (c) 2019 tehprofessor - All Rights Reserved

defmodule EffDB.User do
  import EffDB.Table

  table(
    "users",
    id: :string,
    email: :string,
    password: :virtual,
    password_hash: :string,
    inserted_at: :datetime,
    updated_at: :datetime
  )
#
#  def email_index(transaction, %{id: id} = user) do
#    existing = Transaction.get(transaction, user.email)
#    case existing do
#      nil ->
#        :ok = Transaction.set(transaction, user.email, user.id)
#        {:ok, :email_index_updated}
#      ^id ->
#        {:ok, :email_index_already_exists}
#      _error ->
#        {:error, {:email, :must_be_unique}}
#    end
#  end

  def new(email, password) do
    id = UUID.uuid4()
    %__MODULE__{id: id, email: email, password: password}
  end
end
#
#defimpl EffDB.Schema, for: EffDB.User do
#  alias FDB.{Transaction}
#
#  def name(_schema), do: "users"
#
#  def key(%{id: id}), do: "#{id}"
#
#  def encode(%{password_hash: nil, password: password} = user) do
#    encode(%{user | password_hash: Base.encode64(password)})
#  end
#
#  def encode(%{inserted_at: nil} = user) do
#    current_time = DateTime.utc_now() |> NaiveDateTime.to_erl()
#    encode(%{user | inserted_at: current_time})
#  end
#
#  def encode(%{updated_at: nil} = user) do
#    current_time = DateTime.utc_now() |> NaiveDateTime.to_erl()
#    encode(%{user | updated_at: current_time})
#  end
#
#  def encode(%{email: email, password_hash: password_hash, inserted_at: inserted_at, updated_at: updated_at} = user) do
#    {EffDB.Schema.key(user), email, password_hash, inserted_at, updated_at}
#  end
#
#  def index_coder(%{__struct__: mod} = _user) do
#    Transaction.Coder.new(
#      EffDB.Schematic.index_for_table(mod)
#    )
#  end
#end