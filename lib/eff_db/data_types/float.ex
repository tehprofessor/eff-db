# float.ex
# Created by seve on Oct 24 2019
#
# This is part of the EffDB application.
#
# Copyright (c) 2019 tehprofessor - All Rights Reserved

defmodule EffDB.DataType.Float do
  alias FDB.Coder.{Float}

  use EffDB.DataType

  @impl true
  def cast(value) when is_float(value), do: {:ok, value}
  def cast(bad_value), do: {:error, {:invalid_float, bad_value}}

  @impl true
  def type, do: :float

  @impl true
  def coder(), do: Float.new()
end
