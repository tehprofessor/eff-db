# data_type.ex
# Created by seve on Oct 23 2019
#
# This is part of the EffDB application.
#
# Copyright (c) 2019 tehprofessor - All Rights Reserved

defmodule EffDB.DataType do
  @type t :: primitive | container | extension
  @type primitive :: :integer | :float | :string | :datetime | :identity | :map | :boolean | :uuid
  @type extension :: atom()
  @type container :: {:list, t} | {:map, t}

  @callback cast(any()) :: {:ok, any()} | {:error, {atom(), any()}}
  @callback type() :: t
  @callback coder() :: FDB.Coder.t()

  defmacro __using__(_opts \\ []) do
    quote do
      @behaviour EffDB.DataType

      def new do
        data_type = type()
        data_coder = coder()
        struct(EffDB.DataType, type: data_type, coder: data_coder)
      end
    end
  end

  defstruct [:type, :coder]

  defmodule InvalidDataTypeError do
    defexception [:message]

    @impl true
    def exception(invalid_type) do
      %InvalidDataTypeError{message: "Invalid DataType! No type found for `#{inspect(invalid_type)}`"}
    end
  end

  def type(:string), do: EffDB.DataType.String
  def type(:integer), do: EffDB.DataType.Integer
  def type(:float), do: EffDB.DataType.Float
  def type(:datetime), do: EffDB.DataType.DateTime
  def type(:virtual), do: EffDB.DataType.Virtual
  def type(:uuid), do: EffDB.DataType.UUID
  def type(invalid_type), do: raise InvalidDataTypeError, invalid_type
end
