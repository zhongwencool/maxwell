defmodule Maxwell.Middleware.Retry do
  @moduledoc """
  Retries requests if a connection is refused up to a pre-defined limit.

  Example:
      defmodule MyClient do
        use Maxwell.Builder

        middleware Maxwell.Middleware.Retry, delay: 1_000, max_retries: 3
      end

  Options:

      - delay:        number of milliseconds to wait between tries (defaults to 1_000)
      - max_retries:  maximum number of retries (defaults to 5)
  """
  use Maxwell.Middleware

  @defaults [delay: 1_000, max_retries: 5]

  def init(opts) do
    Keyword.merge(@defaults, opts)
  end

  def call(conn, next, opts) do
    retry_delay = Keyword.get(opts, :delay)
    max_retries = Keyword.get(opts, :max_retries)
    retry(conn, next, retry_delay, max_retries)
  end

  defp retry(conn, next, retry_delay, max_retries) when max_retries > 0 do
    case next.(conn) do
      {:error, :econnrefused, _conn} ->
        :timer.sleep(retry_delay)
        retry(conn, next, retry_delay, max_retries - 1)
      {:error, _reason, _conn} = err ->
        err
      conn ->
        conn
    end
  end
  defp retry(conn, next, _retry_delay, _max_retries) do
    next.(conn)
  end
end
