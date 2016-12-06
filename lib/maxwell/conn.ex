defmodule Maxwell.Conn do
  @moduledoc """
  The Maxwell connection.
  This module defines a `Maxwell.Conn` struct and the main functions
  for working with Maxwell connections.
  ## Request fields
  These fields contain request information:
      * `url` - the requested url as a binary, example: `"www.example.com:8080/path/?foo=bar"`.
      * `method` - the request method as a atom, example: `GET`.
      * `req_headers` - the request headers as a list, example: `[{"content-type", "text/plain"}]`.
      * `req_body` - the request body, by default is an empty string. It is set
         to nil after the request is set.
  ## Response fields
  These fields contain response information:
      * `status` - the response status
      * `resp_headers` - the response headers as a list of tuples.
      * `resp_body` - the response body (todo desc).
  ## Connection fields
      * `state` - the connection state
      * `mode`  - the connection mode
  The connection state is used to track the connection lifecycle. It starts
  as `:unsent` but is changed to `:sending`, Its final result is `:sent` or `:error`.
  The connection mode is used to guide adapter how to request,
  `:direct`, `:stream`. default is ':direct'.

  ## Protocols
  `Maxwell.Conn` implements both the Collectable and Inspect protocols
    out of the box. The inspect protocol provides a nice representation
    of the connection while the collectable protocol allows developers
    to easily chunk data. For example:
         # Send the chunked response headers
         conn = send_chunked(conn, 200)
         # Pipe the given list into a connection
         # Each item is emitted as a chunk
         Enum.into(~w(each chunk as a word), conn)
  """
  @type t :: %__MODULE__{
    mode: :direct | :stream,
    state: :unsent | :sending | :sent | :error,
    method: Atom.t,
    url: String.t,
    path: String.t,
    query_string: Map.t,
    opts: Keyword.t,
    req_headers: %{binary => binary},
    req_body: iodata | Map.t,
    status: non_neg_integer | nil,
    resp_headers: Map.t,
    resp_body: iodata | Map.t
  }

  defstruct mode: :direct,
    state: :unsent,
    method: nil,
    url: "",
    path: "",
    query_string: %{},
    req_headers: %{},
    req_body: nil,
    opts: [],
    status: nil,
    resp_headers: %{},
    resp_body: ""

  @done [:sent, :error]

  alias Maxwell.Conn

  defmodule AlreadySentError do
    defexception message: "the request was already sent"

    @moduledoc """
    Error raised when trying to modify or send an already sent response
    """
  end
  defmodule NotSentError do
    defexception message: "the request was not sent yet"

    @moduledoc """
    Error raised when no request is sent in a connection
    """
  end

  @doc """
  Replace `url` in `conn.url`;
  * `conn` - `%Conn{}`
  * `url` - url string, for example `"http://example.com"`
  ## Examples
  ```ex
  put_url("http://example.com") # %Conn{url: "http://example.com"}
  ```
  """
  def put_url(conn \\ %Conn{}, path)
  def put_url(conn = %Conn{state: :unsent}, url), do: %{conn| url: url}
  def put_url(_conn, _path), do: raise AlreadySentError

  @doc """
  Replace `path` in `conn.path`;
    * `conn` - `%Conn{}`
    * `path` - path string, for example `"/path/to/home"`
  ## Examples
  ```ex
  @middleware Maxwell.Middleware.BaseUrl "http://example.com"
  put_path("delete") # %Conn{path: "delete", url: "http://example.com"}
  ```
  """
  def put_path(conn \\ %Conn{}, path)
  def put_path(conn = %Conn{state: :unsent}, path), do: %{conn| path: path}
  def put_path(_conn, _path), do: raise AlreadySentError

  @doc """
  Add query string to `conn.query_string`
    * `conn` - `%Conn{}`
    * `query_key_or_query_map` - as map, for example `%{foo => bar}`;
                               - as key, for example `foo`.
    * `value` - only valid when query_key_or_query_map as key.

  ## Examples
  ```ex
  # %Conn{query_string: %{name: "zhong wen"}}
  put_query_string(%Conn{}, %{name: "zhong wen"})
  put_query_string(%Conn{}, :name, "zhong wen")
  ```
  """
  def put_query_string(conn \\ %Conn{}, query_key_or_query_map, value \\ nil)
  def put_query_string(conn = %Conn{state: :unsent, query_string: query_string}, key, value) do
    new_query = if value, do: %{key => value}, else: key
    %{conn| query_string: Map.merge(query_string, new_query)}
  end
  def put_query_string(_conn, _key, _value), do: raise AlreadySentError

  @doc """
  Merge http headers.
    * `conn` - `%Conn{}`
    * `req_headers` - query string, for example `%{"content-type" => "text/javascript"}`

  ## Examples
  ```ex
  # %Conn{headers: %{"Content-Type" => "application/json", "User-Agent" => "zhongwenool"}
  %Conn{headers: %{"Content-Type" => "text/javascript"}
  |> put_req_header("Content-Type", "application/json")
  |> put_req_header("User-Agent", "zhongwencool")
  ```
  """
  def put_req_header(conn \\ %Conn{}, key, value \\ nil)
  def put_req_header(conn = %Conn{state: :unsent, req_headers: headers}, key, value) do
    new_headers = if value, do: %{key => value}, else: key
    %{conn| req_headers: Map.merge(headers, new_headers)}
  end
  def put_req_header(_conn, _key, _value), do: raise AlreadySentError

  @doc """
  Merge adapter's request options
  * `conn` - `%Conn{}`
  * `opts` - request's options, for example `[connect_timeout: 4000]`

  ## Examples
  ```ex
  # %Conn{opts: [connect_timeout: 5000, cookie: "xyz"]}
  %Conn{opts: [connect_timeout: 5000]} |> put_option('cookie', "xyz")
  ```
  """
  def put_option(conn \\ %Conn{}, key_or_keyword, value \\ nil)
  def put_option(conn = %Conn{state: :unsent, opts: opts}, key, value) do
    new_opts = if value, do: [{key, value}], else: key
    %{conn| opts: Keyword.merge(opts, new_opts)}
  end
  def put_option(_conn, _key, _value), do: raise AlreadySentError

  @doc """
  Replace req_body
    * `conn` - `%Conn{}`
    * `req_body` - request's body iodata for example `"I Found You"`

  ## Examples
  ```ex
  # %Conn{req_body: "new body"}
  %Conn{req_body: "old body"} |> body("new body")
  ```
  """
  def put_req_body(conn \\ %Conn{}, req_body)
  def put_req_body(conn = %Conn{state: :unsent}, req_body) do
    %{conn| req_body: req_body}
  end
  def put_req_body(_conn, _req_body), do: raise AlreadySentError

  @doc """
  Get response status
  * `conn` - `%Conn{}`

  ## Examples
  ```ex
  # 200
  %Conn{status: 200} |> get_status()
  ```
  """
  def get_status(%Conn{status: status, state: state})when state !== :unsent, do: status
  def get_status(_conn), do: raise NotSentError

  @doc """
  * `get_resp_header/1` - get all response headers, return keyword list
  * `get_resp_header/2` - get response header by key

  * `conn` - `%Conn{}`

  ## Examples
  ```ex
  # "xyz"
  %Conn{resp_headers: %{"cookie" => "xyz"}} |> get_resp_header("cookie")
  # %{"cookie" => "xyz"}
  %Conn{resp_headers: %{"cookie" => "xyz"} |> get_resp_header()
  ```
  """
  def get_resp_header(conn, key \\ nil)
  def get_resp_header(%Conn{state: :unsent}, _key), do: raise NotSentError
  def get_resp_header(%Conn{resp_headers: headers}, nil), do: headers
  def get_resp_header(%Conn{resp_headers: headers}, key), do: headers[key]

  @doc """
  * `get_resp_body/1` - get all response body.
  * `get_resp_body/2` - get response header by key or func.

  * `conn` - `%Conn{}`

  ## Examples
  ```ex
  # "best http client"
  %Conn{resp_body: "best http client" |> get_resp_body
  # "xyz"
  %Conn{resp_body: %{"name" => "xyz"}} |> get_resp_body("name")
  #
  func = fn(x) ->
       [key, value] = String.split(x, ":")
       value
  end
  %Conn{resp_body: "name:xyz" |> get_resp_body(func)
  ```
  """
  def get_resp_body(conn, func \\ nil)
  def get_resp_body(%Conn{state: :unsent}, _keys), do: raise NotSentError
  def get_resp_body(%Conn{resp_body: body}, nil), do: body
  def get_resp_body(%Conn{resp_body: body}, func)when is_function(func, 1), do: func.(body)
  def get_resp_body(%Conn{resp_body: body}, keys)when is_list(keys), do: get_in(body, keys)
  def get_resp_body(%Conn{resp_body: body}, key), do: body[key]

  def append_query_string(url, path, query)when query == %{}, do: url <> path
  def append_query_string(url, path, query) do
    query_string = URI.encode_query(query)
    url <> path <> "?" <> query_string
  end

  defimpl Inspect, for: Conn do
    def inspect(conn, opts) do
      Inspect.Any.inspect(conn, opts)
    end
  end

end

