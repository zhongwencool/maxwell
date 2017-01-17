defmodule Maxwell.Middleware.BaseUrl do
  @moduledoc  """
  Sets the base url for all requests in this module.

  You may provide any valid URL, and it will be parsed into it's requisite parts and
  assigned to the corresponding fields in the connection.

  Providing a path in the URL will be treated as if it's a base path for all requests. If you subsequently
  create a connection and use `put_path`, the base path set in this middleware will be prepended to the
  path provided to `put_path`.

  A base url is not valid if no host is set. You may omit the scheme, and it will default to `http://`.

  ## Examples

      iex> opts = Maxwell.Middleware.BaseUrl.init("http://example.com")
      ...> Maxwell.Middleware.BaseUrl.request(Maxwell.Conn.new("/foo"), opts)
      %Maxwell.Conn{url: "http://example.com", path: "/foo"}

      iex> opts = Maxwell.Middleware.BaseUrl.init("http://example.com/api/?version=1")
      ...> Maxwell.Middleware.BaseUrl.request(Maxwell.Conn.new("/users"), opts)
      %Maxwell.Conn{url: "http://example.com", path: "/api/users", query_string: %{"version" => "1"}}
  """
  use Maxwell.Middleware
  alias Maxwell.Conn

  def init(base_url) do
    conn = Conn.new(base_url)
    opts = %{url: conn.url, path: conn.path, query: conn.query_string}
    case opts.url do
      url when url in [nil, ""] ->
        raise ArgumentError, "BaseUrl middleware expects a proper url containing a hostname, got #{base_url}"
      _ ->
        opts
    end
  end

  def request(%Conn{} = conn, %{url: base_url, path: base_path, query: default_query}) do
    conn
    |> ensure_base_url(base_url)
    |> ensure_base_path(base_path)
    |> ensure_base_query(default_query)
  end

  # Ensures there is always a base url
  defp ensure_base_url(%Conn{url: url} = conn, base_url) when url in [nil, ""] do
    %{conn | url: base_url}
  end
  defp ensure_base_url(conn, _base_url), do: conn

  # Ensures the base path is always present
  defp ensure_base_path(%Conn{path: path} = conn, base_path) when path in [nil, ""] do
    %{conn | path: base_path}
  end
  defp ensure_base_path(%Conn{path: path} = conn, base_path) do
    if String.starts_with?(path, base_path) do
      conn
    else
      %{conn | path: join_path(base_path, path)}
    end
  end

  # Ensures the default query strings are always present
  defp ensure_base_query(%Conn{query_string: qs} = conn, default_query) do
    %{conn | query_string: Map.merge(default_query, qs)}
  end

  defp join_path(a, b) do
    a = String.trim_trailing(a, "/")
    b = String.trim_leading(b, "/")
    a <> "/" <> b
  end
end

