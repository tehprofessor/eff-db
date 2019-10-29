defmodule EffDB.Table do
  alias EffDB.DataType
  alias FDB.Coder.{ByteString, Subspace}

  @table_columns_attribute :effdb_table_columns
  @metadata_tables [EffDB.MetadataTable, EffDB.MetadataEntry]

  # This is a private protocol, it's used internally to EffDB and should not
  # be used by downstream applications/libraries.
  defprotocol TableTuple do
    def table_name(table)
    def table_tuple(table)
    def table_primary_key(table_row)
    def cast(table_row)
  end

  defmodule Record do
    defstruct [:table_name, :values, :errors]

    @type t :: %__MODULE__{}

    def new(table_name, values, errors) do
      %__MODULE__{table_name: table_name, values: values, errors: errors}
    end

    def to_tuple(%{values: values}) do
      List.to_tuple(values)
    end

    def valid?(%__MODULE__{errors: []}), do: true
    def valid?(%__MODULE__{errors: _}), do: false
  end

  def cast(table_row) do
    TableTuple.cast(table_row)
  end

  def table_primary_key(table_row) do
    TableTuple.table_primary_key(table_row)
  end

  def table_name(schema) do
    TableTuple.table_name(schema)
  end

  def table_tuple(schema) do
    TableTuple.table_tuple(schema)
  end

  @spec table_coder(table_mod :: module()) :: FDB.Transaction.Coder.t()
  def table_coder(table_mod) do
    table_subspace = new_subspace(table_mod.table_name())
    table_tuple = table_mod.table_tuple()

    FDB.Transaction.Coder.new(table_subspace, table_tuple)
  end

  @doc """
  Retrieve all the tables registered with the application.
  """
  @spec list_tables() :: [module()]
  def list_tables do
    Protocol.extract_impls(EffDB.Table.TableTuple, :code.get_path())
    |> Enum.reject(&(&1 in @metadata_tables))
  end

  @doc """
  Generates a table schema from the field definitions. Doing so by hand is very
  error prone as the fields themselves are _ordered_ when stored in foundation.
  """
  defmacro table(table_name, columns) do
    # Grab the module calling the macro
    mod = List.first(__CALLER__.context_modules)

    # Create a module attribute to store table keys for use in the struct.
    Module.register_attribute(mod, @table_columns_attribute, accumulate: true)
    persisted_fields = Enum.filter(columns, fn {_name, type} -> type != :virtual end)
    virtual_fields = Enum.filter(columns, fn {_name, type} -> type == :virtual end)

    # Setup functions for fields that will be persisted to foundation.
    persisted_fields = for {{name, type}, index} <- Enum.with_index(persisted_fields) do
      data_type = DataType.type(type)
      Module.put_attribute(mod, @table_columns_attribute, name)


      quote do
        # Creates a function based on the column (key) name that returns the
        # column's data type.
        #
        # Ex. Using `:email` as the column name:
        #
        # def email(val \\ nil), do: EffDB.DataType.String.coder()
        @doc """
        Returns the column type coder for #{unquote(name)}. This function is
        consumed by `field_coder_at_index` which is used for serializing the tuple
        to foundation.
        """
        def unquote(name)(val \\ nil) do
          unquote(data_type).coder()
        end

        def cast(unquote(name), value) do
          unquote(data_type).cast(value)
        end

        def column_metadata_at_index(unquote(index)) do
          {unquote(index), Atom.to_string(unquote(name)), Atom.to_string(unquote(type))}
        end

        # Foundation stores everything in tuples, and that read/writes must
        # maintain the same ordering of columns so the tuple is (de)serialized
        # consistently and correctly.
        #
        # `field_coder_at_index` takes a index, and returns the corresponding email.
        #
        # Ex. Using `1` as the field's position, assuming `name/0`; which, is
        # setup above, we can expect the function to be generated:
        #
        # def field_coder_at_index(1), do: email()
        @doc """
        Returns the column type coder for the index.
        """
        def field_coder_at_index(unquote(index)), do: __MODULE__.unquote(name)()

        @doc """
        Return the value of the field at the given index for the provided record.
        """
        def field_value_at_index(record, unquote(index)) do
          %{unquote(name) => value} = record

          {unquote(name), value}
        end
      end
    end

    virtual_fields = for {name, type} <- virtual_fields do
      data_type = DataType.type(type)
      Module.put_attribute(mod, @table_columns_attribute, name)

      quote do
        @doc """
        Returns nil, #{unquote(name)} is a virtual attribute and should not be persisted
        to foundation. This signals to EffDB to exclude it from the tuple.
        """
        def unquote(name)(val \\ nil), do: unquote(data_type).coder()
      end
    end

    # The number of columns
    column_count = Enum.count(persisted_fields)

    # Make sure we've got the persisted + virtual keys
    keys_for_struct = Module.get_attribute(mod, @table_columns_attribute)

    quote do
      @after_compile EffDB.Table

      # Define a struct with the keys
      defstruct unquote(keys_for_struct)

      alias FDB.Coder.{ByteString, Integer, NestedTuple, Subspace, Tuple}

      @doc """
      The count of columns to be persisted from this record.

      Note: Virtual columns are not included in this count since they are not persisted.
      """
      def column_count, do: unquote(column_count)

      # Install functions for the the persisted fields
      unquote(persisted_fields)

      # Install functions for the virtual fields
      unquote(virtual_fields)

      @doc """
      Returns a string with the name of the table. This value is used for
      creating a subspace within foundation to store our data.
      """
      def table_name, do: unquote(table_name)

      @doc """
      Returns the primary key for the given table record.
      """
      def primary_key(%_{id: id}), do: id

      @doc """
      A tuple containing the "#{unquote(table_name)}" table fields used for
      writing to Foundation.
      """
      def table_tuple() do
        count = column_count() - 1
        schema_list = for n <- 0..count, do: field_coder_at_index(n)

        List.to_tuple(schema_list)
        |> Tuple.new()
      end

      @doc """
      Cast the table to a record struct.
      """
      def cast(%__MODULE__{} = record) do
        count = column_count() - 1
        # Count down through all the field values reverse the order of the fields
        record_values = for n <- count..0, do: field_value_at_index(record, n)

        record = Enum.reduce(record_values, %Record{values: [], errors: []}, fn {column_name, value}, accum ->
          case cast(column_name, value) do
            {:ok, value} -> %{accum | values: [value | accum.values]}
            {:error, message} -> %{accum | errors: [{column_name, message} | accum.errors]}
          end
        end)

        %{record | table_name: table_name()}
      end
    end
  end

  @doc """
  Implements the `EffDB.Table.TableTuple` protocol for the table module. This provides a
  really handy way to look up tables to initialize in foundation at runtime.
  """
  defmacro __after_compile__(env, _bytecode) do
    mod = List.first(env.context_modules)

    quote do
      defimpl EffDB.Table.TableTuple, for: unquote(mod) do
        def table_name(_), do: unquote(mod).table_name()
        def table_tuple(_), do: unquote(mod).table_tuple()
        # TODO: Rename this to primary_key.
        def table_primary_key(instance), do: unquote(mod).primary_key(instance)
        def cast(instance), do: unquote(mod).cast(instance)
      end
    end
  end

  # Constructs a prefix with the `subspace_prefix`, using the `ByteString`
  # coder, and then sets the coder for new keys in the subspace to be a
  # ByteString. This gives us keys more or less like:
  #
  # `"users", "$PRIMARY_KEY"`
  #
  # where $PRIMARY_KEY is the user's primary key value.
  defp new_subspace(name_prefix) do
    Subspace.new({name_prefix, ByteString.new()}, ByteString.new())
  end
end
