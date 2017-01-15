defmodule Maxwell.Middleware do
  @moduledoc  """
  Example see `Maxwell.Middleware.BaseUrl`
  """

  @type opts :: any
  @type next_fn :: (Maxwell.Conn.t -> Maxwell.Conn.t)
  @type success :: Maxwell.Conn.t
  @type failure :: {:error, reason :: term()}

  @callback init(opts) :: opts
  @callback call(Maxwell.Conn.t, next_fn, opts) :: success | failure
  @callback request(Maxwell.Conn.t, opts :: term()) :: success | failure
  @callback response(Maxwell.Conn.t, opts :: term()) :: success | failure

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Maxwell.Middleware

      @doc false
      @spec init(Maxwell.Middleware.opts) :: Maxwell.Middleware.opts
      def init(opts), do: opts

      @doc false
      @spec call(Maxwell.Conn.t, Maxwell.Middleware.next_fn, Maxwell.Middleware.opts)
        :: Maxwell.Middleware.success | Maxwell.Middleware.failure
      def call(%Maxwell.Conn{} = conn, next, opts) do
        with %Maxwell.Conn{} = conn <- request(conn, opts),
             %Maxwell.Conn{} = conn <- next.(conn),
          do: response(conn, opts)
      end

      @doc false
      @spec request(Maxwell.Conn.t, Maxwell.Middleware.opts)
        :: Maxwell.Middleware.success | Maxwell.Middleware.failure
      def request(%Maxwell.Conn{} = conn, opts) do
        conn
      end

      @doc false
      @spec response(Maxwell.Conn.t, Maxwell.Middleware.opts)
        :: Maxwell.Middleware.success | Maxwell.Middleware.failure
      def response(%Maxwell.Conn{} = conn, opts) do
        conn
      end

      defoverridable [request: 2, response: 2, call: 3, init: 1] end
  end

end

