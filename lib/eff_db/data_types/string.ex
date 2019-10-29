# string.ex
# Created by seve on Oct 23 2019
#
# This is part of the EffDB application.
#
# Copyright (c) 2019 tehprofessor - All Rights Reserved

defmodule EffDB.DataType.String do
  alias FDB.Coder.ByteString

  use EffDB.DataType

  @impl true
  def cast(value) when is_binary(value), do: {:ok, value}

  def cast(bad_value), do: {:error, {:invalid_string, bad_value}}

  @impl true
  def type, do: :string

  @impl true
  def coder(), do: ByteString.new()
end
