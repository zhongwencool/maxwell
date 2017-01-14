if Code.ensure_loaded?(:fuse) do
defmodule Maxwell.Middleware.Fuse do
  @moduledoc """
  A circuit breaker middleware which uses [fuse](https://github.com/jlouis/fuse) under the covers.

  To use this middleware, you will need to add `{:fuse, "~> 2.4"}` to your dependencies, and
  the `:fuse` application to your applications list in `mix.exs`.

  Example:

      defmodule CircuitBreakerClient do
        use Maxwell.Builder

        middleware Maxwell.Middleware.Fuse,
          name: __MODULE__,
          fuse_opts: {{:standard, 2, 10_000}, {:reset, 60_000}}
      end

  Options:

      - `:name` - The name of the fuse, required
      - `:fuse_opts` - Options to pass along to `fuse`. See `fuse` docs for more information.
  """
  use Maxwell.Middleware

  # These options were borrowed from http://blog.rokkincat.com/circuit-breakers-in-elixir/
  # You should tweak them for your use case, as these defaults are likely unsuitable.
  @default_fuse_opts {{:standard, 2, 10_000}, {:reset, 60_000}}

  @default_opts [fuse_opts: @default_fuse_opts]

  def init(opts) do
    _name = Keyword.fetch!(opts, :name)
    Keyword.merge(@default_opts, opts)
  end

  def call(conn, next, opts) do
    name = Keyword.get(opts, :name)
    conn = case :fuse.ask(name, :sync) do
      :ok ->
        run(conn, next, name)
      :blown ->
        {:error, :econnrefused, conn}
      {:error, :not_found} ->
        :fuse.install(name, Keyword.get(opts, :fuse_opts))
        run(conn, next, name)
    end
    case conn do
      %Maxwell.Conn{} = conn -> response(conn, opts)
      err -> err
    end
  end

  defp run(conn, next, name) do
    case next.(conn) do
      {:error, _reason, _conn} = err ->
        :fuse.melt(name)
        err
      res ->
        res
    end
  end
end
end
