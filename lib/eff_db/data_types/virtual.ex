# virtual.ex
# Created by seve on Oct 24 2019
#
# This is part of the EffDB application.
#
# Copyright (c) 2019 tehprofessor - All Rights Reserved

defmodule EffDB.DataType.Virtual do

  use EffDB.DataType

  @impl true
  def cast(value), do: {:ok, value}

  @impl true
  def type, do: :virtual

  @impl true
  def coder(), do: nil
end
