# document.ex
# Created by seve on Oct 23 2019
#
# This is part of the EffDb application.
#
# Copyright (c) 2019 tehprofessor - All Rights Reserved

defmodule EffDB.Document do
  import EffDB.Table

  table(
    "documents",
    id: :string,
    title: :string,
    body: :string,
    subject: :string,
    slug: :string,
    published_at: :datetime,
    inserted_at: :datetime,
    updated_at: :datetime
  )

  def table_indexes, do: [:id, :slug]

  #  def slug_index(transaction, %{id: id} = document) do
  #    existing = Transaction.get(transaction, document.slug)
  #    case existing do
  #      nil ->
  #        :ok = Transaction.set(transaction, document.slug, document.id)
  #        {:ok, :slug_index_updated}
  #      ^id ->
  #        {:ok, :slug_index_already_exists}
  #      _error ->
  #        {:error, {:slug, :must_be_unique}}
  #    end
  #  end


  @spec new(title :: String.t(), subject :: String.t(), slug :: String.t(), body :: String.t()) :: %__MODULE__{}
  def new(title, subject, slug, body) do
    id = UUID.uuid4()
    %__MODULE__{id: id, title: title, subject: subject, slug: slug, body: body}
  end
end
#
#defimpl EffDB.Schema, for: EffDB.Document do
#  alias FDB.{Transaction}
#
#  def name(_schema), do: "documents"
#
#  def key(%{id: id}), do: "#{id}"
#
#  def encode(%{inserted_at: nil} = document) do
#    current_time = DateTime.utc_now() |> NaiveDateTime.to_erl()
#    encode(%{document | inserted_at: current_time})
#  end
#
#  def encode(%{published_at: nil} = document) do
#    {:ok, unpublished_time} = DateTime.from_unix(0)
#    unpublished_time = NaiveDateTime.to_erl(unpublished_time)
#    encode(%{document | published_at: unpublished_time})
#  end
#
#  def encode(%{updated_at: nil} = document) do
#    current_time = DateTime.utc_now() |> NaiveDateTime.to_erl()
#    encode(%{document | updated_at: current_time})
#  end
#
#  def encode(%{title: title, body: body, subject: subject, slug: slug, inserted_at: inserted_at, published_at: published_at, updated_at: updated_at} = document) do
#    {EffDB.Schema.key(document), title, body, subject, slug, published_at, inserted_at, updated_at}
#  end
#
#  def index_coder(%{__struct__: mod} = _document) do
#    Transaction.Coder.new(
#      EffDB.Schematic.index_for_table(mod)
#    )
#  end
#end