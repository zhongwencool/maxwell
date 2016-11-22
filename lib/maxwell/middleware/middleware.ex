defmodule Maxwell.Middleware do
@moduledoc  """
  Example see `Maxwell.Middleware.BaseUrl`
  """

  @type opts :: any
  @type next_fn :: (Maxwell.t -> Maxwell.t)

  @callback init(opts) :: opts
  @callback call(Maxwell.t, next_fn, opts) :: Maxwell.t

  defmacro __using__(_opts) do
    quote do
      @behaviour Maxwell.Middleware

      def init(opts), do: opts

      defoverridable [init: 1]
    end
  end
end
