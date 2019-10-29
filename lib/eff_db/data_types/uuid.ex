# uuid.ex
# Created by seve on Oct 24 2019
#
# This is part of the EffDB application.
#
# Copyright (c) 2019 tehprofessor - All Rights Reserved

defmodule EffDB.DataType.UUID do
  alias FDB.Coder.UUID, as: CoderUUID

  use EffDB.DataType

  @impl true
  def cast(value) when is_binary(value) do
    case UUID.info(value) do
      {:ok, _info} -> {:ok, value}
      {:error, _} -> {:error, {:invalid_uuid_format, value}}
    end
  end

  def cast(bad_value), do: {:error, {:invalid_uuid, bad_value}}

  @impl true
  def type, do: :uuid

  @impl true
  def coder(), do: CoderUUID.new()
end
