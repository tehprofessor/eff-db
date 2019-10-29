# date_time.ex
# Created by seve on Oct 23 2019
#
# This is part of the EffDB application.
#
# Copyright (c) 2019 tehprofessor - All Rights Reserved

# TODO: Make time higher-resolution. Right now it's not saving any information
# about the timezone and seconds are pretty low resolution for anything useful.

defmodule EffDB.DataType.DateTime do
  @moduledoc """
  Mapping between an EffDB :datetime type, and it's backing type in foundation.
  Note: Does not yet support timezones
  """
  alias FDB.Coder.{Integer, NestedTuple}

  use EffDB.DataType

  @impl true
  def cast(value) when is_binary(value) do
    with {:ok, naive_dt} <- NaiveDateTime.from_iso8601(value) do
      {:ok, NaiveDateTime.to_erl(naive_dt)}
    else
      {:error, :invalid_format} -> {:error, {:invalid_datetime_format, value}}
    end
  end

  def cast(%{calendar: _, year: _, month: _, day: _, hour: _, minute: _, second: _, microsecond: _} = dt) do
    {:ok, NaiveDateTime.to_erl(dt)}
  end

  def cast(bad_value), do: {:error, {:invalid_datetime, bad_value}}

  @impl true
  def type, do: :datetime

  @impl true
  def coder() do
    NestedTuple.new({
      # Year, Month, Date
      NestedTuple.new({Integer.new(), Integer.new(), Integer.new()}),
      # Hour, Minute, Second
      NestedTuple.new({Integer.new(), Integer.new(), Integer.new()})
    })
  end
end
