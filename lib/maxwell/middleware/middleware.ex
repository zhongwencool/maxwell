defmodule Maxwell.Middleware do
@moduledoc  """
  Example see `Maxwell.Middleware.BaseUrl`
  """

  @doc """
   ```
    @middleware Middleware.Module, opts\\[]
   ```
  """
  @callback call(env :: map(), next :: any(), opts :: term()) :: map()
  @callback request(env :: map(), opts :: term()) :: map()
  @callback response(result :: {:ok, map()}| {:error, reason :: term()}, opts :: term()) :: {:ok, map()} | {:error, reason :: term()}

  defmacro middleware(middleware, opts\\[]) do
    quote do
      @middleware {unquote(middleware), unquote(opts)}
    end
  end

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Maxwell.Middleware

      @doc false
      def call(env, next, opts) do
        env = request(env, opts)
        env = next.(env)
        response(env, opts)
      end

      @doc false
      def request(env, opts) do
        env
      end

      @doc false
      def response(env, opts) do
        env
      end

      defoverridable [request: 2, response: 2, call: 3] end
  end
end

