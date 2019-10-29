# def_context.ex
# Created by seve on Oct 26 2019
#
# This is part of the EffDB application.
#
# Copyright (c) 2019 tehprofessor - All Rights Reserved

defmodule DefContext do
  @moduledoc """
  Creates a `Context` module for managing dependencies at runtime, because
  state is bad. State makes bug difficult to track down, code hard to refactor,
  and in Elixir, IMHO, have a giant state footgun named `Application.get_env`.
  """

  @doc """
  Imports the DefContext module making the `defcontext` macro available.
  """
  defmacro __using__(_opts \\ []) do
    quote do
      import DefContext
    end
  end

  @doc """
  Defines a `Context` module within the current scope, using the `keys`,
  to define a struct containing runtime dependencies.

  NOTE: All keys provided to `defcontext` MUST be present in `Config.ex`

  ## Example
  Below is a complete example including defining a context with `defcontext`,
  using the context, and finally what generated Context would look like.

  ### Definition & Usage
  Here is a module named `LeModule`, which relies on two runtime dependencies
  an external api for a third-party service and a cache memoize the results.
      defmodule LeModule do
        # `use` (which imports `DefContext`) to get things rollin'
        use DefContext

        # Define context
        defcontext :external_api, :cache

        # Define our function, making the context an optional call, we will
        # pattern match below and setup a default context when it's nil.
        def get(context \\ nil, id)

        # Load the default context configuration from `Config`
        def get(nil, id) do
          context = LeModule.Context.new()
          get(context, id)
        end

        # Finally, do the call using the given context.
        def get(%{external_api: api}, id) do
          api.get(id)
        end
      end
  ### Generated Context Module
      defmodule LeModule.Context do
        alias EffDB.Config, as: Config

        defstruct [:external_api, :cache]
        @type t :: %Context{}

        def new, do: defaults() |> new()
        def new(overrides), do: struct(__MODULE__, overrides)

        def defaults do
          [
            external_api: Config.external_api(),
            cache: Config.cache(),
          ]
        end
      end
  """
  defmacro defcontext(keys) do
    # Create quoted key/value using the key and it's corresponding Config func.
    defaults = for key <- keys do
      quote do
        {unquote(key), Config.unquote(key)}
      end
    end

    quote do
      defmodule Context do
        alias EffDB.Config, as: Config
        defstruct unquote(keys)
        @type t() :: %Context{}

        @doc """
        Creates a new Context using the current runtime configuration.
        """
        def new(), do: defaults() |> new()

        @doc """
        Creates a new Context using the given overrides.
        """
        def new(overrides), do: struct(__MODULE__, overrides)

        @doc """
        The current configured values for the context keys.
        """
        def defaults do
          unquote(defaults)
        end
      end

      # Now alias it for make benefit easy codez
      alias __MODULE__.Context
    end
  end
end
