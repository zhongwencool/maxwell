defmodule Maxwell.Middleware do
@moduledoc  """
  Example see `Maxwell.Middleware.BaseUrl`
  """

  @type opts :: any
  @type next_fn :: (Maxwell.t -> Maxwell.t)

  @callback init(opts) :: opts
  @callback call(Maxwell.t, next_fn, opts) :: Maxwell.t

  defmodule DSL do
    @moduledoc """
    DSL to simplify creating `Maxwell.Middleware`
    """
    @next_fn quote do: next__call
    @env quote do: env

    defmacro next() do
      quote do
        var!(unquote(@next_fn)).(var!(unquote(@env)))
      end
    end

    defmacro next(args) do
      quote do
        var!(unquote(@next_fn)).(unquote(args))
      end
    end

    defmacro defcall(opts, [do: block]) do
      quote do
        def call(var!(unquote(@env)), var!(unquote(@next_fn)), unquote(opts)) do
          unquote(block)
        end
      end
    end
  end

  defmacro __using__(_opts) do
    quote do
      @behaviour Maxwell.Middleware
      import Maxwell.Middleware.DSL

      def init(opts), do: opts

      defoverridable [init: 1]
    end
  end
end
