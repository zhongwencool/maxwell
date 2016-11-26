defmodule Maxwell.Middleware do
  @moduledoc  """
  Example see `Maxwell.Middleware.BaseUrl`
  """

  @type opts :: any
  @type next_fn :: (Maxwell.Conn.t -> Maxwell.Conn.t)
  @callback init(opts) :: opts
  @callback call(Maxwell.Conn.t, next_fn, opts) :: Maxwell.Conn.t
  @callback request(Maxwell.Conn.t, opts :: term()) :: Maxwell.Conn.t
  @callback response(result :: {:ok, Maxwell.Conn.t} | {:error,reason :: term()}, opts :: term())::
  {:ok, Maxwell.Conn.t} | {:error, reason :: term()}

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

