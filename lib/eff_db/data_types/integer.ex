# integer.ex
# Created by seve on Oct 24 2019
#
# This is part of the Default (Template) Project application.
#
# Copyright (c) 2019 tehprofessor - All Rights Reserved

defmodule EffDB.DataType.Integer do
  alias FDB.Coder.Integer

  use EffDB.DataType

  @impl true
  def cast(value) when is_integer(value), do: {:ok, value}
  def cast(bad_value), do: {:error, {:invalid_integer, bad_value}}

  @impl true
  def type, do: :integer

  @impl true
  def coder(), do: Integer.new()
end
