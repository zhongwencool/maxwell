defmodule Maxwell.Conn do
  @moduledoc """
  The Maxwell connection.
  This module defines a `Maxwell.Conn` struct and the main functions
  for working with Maxwell connections.
  """

  @type t :: %__MODULE__{
    url: String.t,
    method: String.t,
    headers: Map.t,
    body: binary,
    opts: Keyword.t,
    status: integer
  }

  defstruct url: "",
    method: nil,
    headers: %{},
    body: nil,
    opts: [],
    status: nil

  @doc """
  1. Append path to base url;
  2. Replace the base url if path is begin with http.
  ```ex
  @middleware Maxwell.Middleware.BaseUrl "http://example.com"

  url("delete") # %Maxwell.Conn{url: "http://example.com/delete"}
  url("http://next.com/create") # %Maxwell.Conn{url: "http://next.com/create"}
  ```
  """
  def url(conn \\ %Maxwell.Conn{}, url)when is_binary(url) do
    %{conn| url: url}
  end
  @doc """
  Add query string to base url, encode query by `URI.encode_query`.
  ```ex
  # %Maxwell.Conn{url: "http://example.com?name=zhong+wen"}
  %Maxwell.Conn{url: "http://example.com"} |> query(%{name: "zhong wen"})
  ```
  """
  def query(conn \\ %Maxwell.Conn{}, query)when is_map(query) do
    %{conn| url: append_query_string(conn.url, query)}
  end
  @doc """
  Merge http headers.
  ```ex
  # %Maxwell.Conn{headers: %{"Content-Type": "application/json", "User-Agent": 'zhongwenool'}
  %Maxwell.Conn{headers: %{'Content-Type': "text/javascript"}}
  |> headers(%{'Content-Type': "application/json", 'User-Agent': 'zhongwen'})
  ```
  """
  def headers(conn \\ %Maxwell.Conn{}, headers)when is_map(headers) do
    %{conn| headers: Map.merge(conn.headers, headers)}
  end
  @doc """
  Merge adapter's connect options
  ```ex
  # %Maxwell.Conn{opts: [connect_timeout: 5000, cookie: "xyz"]}
  %Maxwell.Conn{opts: [connect_timeout: 5000]} |> opts(['cookie': "xyz"])
  ```
  """
  def opts(conn \\ %Maxwell.Conn{}, opts)when is_list(opts) do
    %{conn| opts: Keyword.merge(conn.opts, opts)}
  end
  @doc """
  Replace body
  ```ex
  # %Maxwell.Conn{body: "new body"}
  %Maxwell.Conn{body: "old body"} |> body("new body")
  ```
  """
  def body(conn \\ %Maxwell.Conn{}, body) do
    %{conn| body: body}
  end
  @doc """
  Replace body by `{:multipart, multipart}`
  ```ex
  # %Maxwell.Conn{body: {:multipart, multipart}}
  %Maxwell.Conn{} |> multipart(multipart)
  ```
  """
  def multipart(conn \\ %Maxwell.Conn{}, multipart) do
    %{conn| body: {:multipart, multipart}}
  end
  @doc """
  Send response to target_pid asynchronous
  """
  def respond_to(target_pid)when is_pid(target_pid) do
    respond_to(%Maxwell.Conn{}, target_pid)
  end
  def respond_to(%Maxwell.Conn{} = conn) do
    respond_to(conn, self)
  end
  @doc """
  Send response to target_pid asynchronous
  """
  def respond_to(conn, target_pid) do
    target_pid = target_pid || self()
    %{conn| opts: Keyword.merge(conn.opts, [{:respond_to, target_pid}])}
  end

  @doc """
  Encode query and append to base url
  base_url = http://example.com
  query    = %{uid: 1, name: "zhongwen}
  result   = http://example.com?uid=1&name=zhongwen
  """
  def append_query_string(url, query) do
    if query != %{} do
      query_string = URI.encode_query(query)
      if String.contains?(url, "?") do
        url <> "&" <> query_string
      else
        url <> "?" <> query_string
      end
    else
      url
    end
  end

end

