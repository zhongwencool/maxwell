defmodule Maxwell.Middleware do
  @moduledoc  """
  Example see `Maxwell.Middleware.BaseUrl`
  """

  @type opts :: any
  @type next_fn :: (Maxwell.t -> Maxwell.t)
  @callback init(opts) :: opts
  @callback call(Maxwell.t, next_fn, opts) :: Maxwell.t
  @callback request(Maxwell.t, opts :: term()) :: Maxwell.t
  @callback response(result :: {:ok, Maxwell.t}| {:error, reason :: term()}, opts :: term()) :: {:ok, Maxwell.t} | {:error, reason :: term()}

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Maxwell.Middleware

      @doc false
      def init(opts), do: opts

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

      defoverridable [request: 2, response: 2, call: 3, init: 1] end
  end
  
end

