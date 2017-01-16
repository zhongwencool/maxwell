defmodule Maxwell.Conn do
  @moduledoc """
  The Maxwell connection.
  This module defines a `Maxwell.Conn` struct and the main functions
  for working with Maxwell connections.

  ### Request fields
  These fields contain request information:

     * `url` - the requested url as a binary, example: `"www.example.com:8080/path/?foo=bar"`.
     * `method` - the request method as a atom, example: `GET`.
     * `req_headers` - the request headers as a list, example: `[{"content-type", "text/plain"}]`.
     * `req_body` - the request body, by default is an empty string. It is set
        to nil after the request is set.

  ### Response fields
  These fields contain response information:

     * `status` - the response status
     * `resp_headers` - the response headers as a list of tuples.
     * `resp_body` - the response body (todo desc).

  ### Connection fields

     * `state` - the connection state
  The connection state is used to track the connection lifecycle. It starts
  as `:unsent` but is changed to `:sending`, Its final result is `:sent` or `:error`. 

  ### Protocols
  `Maxwell.Conn` implements both the Collectable and Inspect protocols
    out of the box. The inspect protocol provides a nice representation
    of the connection while the collectable protocol allows developers
    to easily chunk data. For example:

         # Send the stream request headers
         conn = post(conn, :stream)
         # Pipe the given list into a connection
         # Each item is emitted as a stream
         Enum.into(~w(each chunk as a word), conn)

  """
  @type conn_t :: %__MODULE__{
    state: :unsent | :sending | :sent | :error,
    method: Atom.t,
    url: String.t,
    path: String.t,
    query_string: Map.t,
    opts: Keyword.t,
    req_headers: %{binary => {binary, binary}},
    req_body: iodata | Map.t,
    status: non_neg_integer | nil,
    resp_headers: %{binary => {binary, binary}},
    resp_body: iodata | Map.t
  }

  defstruct state: :unsent,
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

  alias Maxwell.Conn

  defmodule AlreadySentError do
    defexception message: "the request was already sent"

    @moduledoc """
    Error raised when trying to modify or send an already sent request
    """
  end
  defmodule NotSentError do
    defexception message: "the request was not sent yet"

    @moduledoc """
    Error raised when no request is sent in a connection
    """
  end

  @doc """
  Create a `%Maxwell.Conn{}`

  * `url` - the base url.

  ### Examples

      # %Maxwell.Conn{}
      conn = new()
      # %Maxwell.Conn{url = "http://example.com"}
      conn = new("http://example.com")

  """
  def new(url \\ ""), do: %Maxwell.Conn{url: url}

  @doc """
  Replace `path` in `conn.path`.

    * `path` - path string, for example `"/path/to/home"`
    * `conn` - `%Conn{}`

  ### Examples

       @middleware Maxwell.Middleware.BaseUrl "http://example.com"
       #%Conn{path: "delete", url: "http://example.com"}
       put_path("delete")
       #or
       new() |> put_path("delete")

  """
  def put_path(conn \\ %Conn{}, path)
  def put_path(conn = %Conn{state: :unsent}, path), do: %{conn| path: path}
  def put_path(_conn, _path), do: raise AlreadySentError

  @doc """
  Add query string to `conn.query_string`.

    * `conn` - `%Conn{}`
    * `query_map` - as map, for example `%{foo => bar}`

  ### Examples

      # %Conn{query_string: %{name: "zhong wen"}}
      put_query_string(%Conn{}, %{name: "zhong wen"})

  """
  def put_query_string(conn \\ %Conn{}, query_map)
  def put_query_string(conn = %Conn{state: :unsent, query_string: query_string}, query_map) do
    %{conn| query_string: Map.merge(query_string, query_map)}
  end
  def put_query_string(_conn, _query_map), do: raise AlreadySentError

  @doc """
  Add query string to `conn.query_string`.

  * `conn` - `%Conn{}`
  * `key` - query key, for example `"name"`.
  * `value` - query value, for example `"lucy"`.

  ### Examples

        # %Conn{query_string: %{name: "zhong wen"}}
        put_query_string(%Conn{}, :name, "zhong wen")

  """
  def put_query_string(conn = %Conn{state: :unsent, query_string: query_string}, key, value) do
    %{conn| query_string: Map.put(query_string, key, value)}
  end
  def put_query_string(_conn, _key, _value), do: raise AlreadySentError

  @doc """
  Merge http headers.

    * `conn` - `%Conn{}`
    * `req_headers` - reqeust headers, for example `%{"content-type" => "text/javascript"}`

  ### Examples

      # %Conn{headers: %{"Content-Type" => "application/json", "User-Agent" => "zhongwenool"}
      %Conn{headers: %{"Content-Type" => "text/javascript"}
      |> put_req_header(%{"Content-Type" => "application/json"})
      |> put_req_header(%{"User-Agent" => "zhongwencool"})

  """
  def put_req_header(conn \\ %Conn{}, map_headers)
  def put_req_header(conn = %Conn{state: :unsent, req_headers: headers}, map_headers)when is_map(map_headers) do
    downcase_func =
    fn({downcase_header, {_original_header, _header_value} = value}, acc) ->
      Map.put(acc, downcase_header, value)
      ({header, _val} = value, acc) ->
        Map.put(acc, String.downcase(header), value)
    end
    new_headers = Enum.reduce(map_headers, headers, downcase_func)
    %{conn| req_headers: new_headers}
  end
  def put_req_header(_conn, _map_headers), do: raise AlreadySentError

  @doc """
  Merge http headers.

  * `conn` - `%Conn{}`
  * `key` - header key
  * `value` - header value

  ### Examples

      # %Conn{headers: %{"content-type" => {"Content-Type", "application/json"}, "user-agent" => {"user-agent", "zhongwenool"}}
      %Conn{headers: %{"content-type" => {"Content-Type", "text/javascript"}}
      |> put_req_header("Content-Type", "application/json")
      |> put_req_header("User-Agent", "zhongwencool")

  """
  def put_req_header(conn = %Conn{state: :unsent, req_headers: headers}, key, value) do
    %{conn| req_headers: Map.put(headers,  String.downcase(key), {key, value})}
  end
  def put_req_header(_conn, _key, _value), do: raise AlreadySentError

  @doc """

  * `get_req_header/1` - get all request headers, return `Map.t`.
  * `get_req_header/2` - get request header by `key`, return value.
  * `conn` - `%Conn{}`

  ### Examples

  # {"Cookie", "xyz"}
  %Conn{req_headers: %{"cookie" => {"Cookie", "xyz"}} |> get_req_header("cookie")
  # %{"Cookie" => "xyz"}
  %Conn{req_headers: %{"cookie" => {"Cookie", "xyz"}} |> get_req_header
  """
  def get_req_header(conn, key \\ nil)
  def get_req_header(%Conn{req_headers: headers}, nil) do
    for {_, origin_header} <- headers, into: %{}, do: origin_header
  end
  def get_req_header(%Conn{req_headers: headers}, key), do: headers[key] || headers[String.downcase(key)]

  @doc """
  Merge adapter's request options.

   * `conn` - `%Conn{}`.
   * `opts` - request's options, for example `[connect_timeout: 4000]`.
   * `key_or_keyword` - for example: `:cookie` or `[cookie: "xyz"]`.
   * `value` - for example: "xyz", only valid when `key_or_keyword` is a key.

  ### Examples

      # %Conn{opts: [connect_timeout: 5000, cookie: "xyz"]}
      %Conn{opts: [connect_timeout: 5000]} |> put_option('cookie', "xyz")
  """
  def put_option(conn \\ %Conn{}, key_or_keyword, value \\ nil)
  def put_option(conn = %Conn{state: :unsent, opts: opts}, key, value) do
    new_opts = if value, do: [{key, value}], else: key
    %{conn| opts: Keyword.merge(opts, new_opts)}
  end
  def put_option(_conn, _key, _value), do: raise AlreadySentError

  @doc """
  Replace req_body.

    * `conn` - `%Conn{}`
    * `req_body` - request's body iodata for example `"I Found You"`

  ### Examples
      # %Conn{req_body: "new body"}
      %Conn{req_body: "old body"} |> body("new body")
  """
  def put_req_body(conn \\ %Conn{}, req_body)
  def put_req_body(conn = %Conn{state: :unsent}, req_body) do
    %{conn| req_body: req_body}
  end
  def put_req_body(_conn, _req_body), do: raise AlreadySentError

  @doc """
  Get response status, raise `Maxwell.Conn.NotSentError` when request is unsent.
  * `conn` - `%Conn{}`

  ### Examples

      # 200
      %Conn{status: 200} |> get_status()
  """
  def get_status(%Conn{status: status, state: state})when state !== :unsent, do: status
  def get_status(_conn), do: raise NotSentError

  @doc """

  * `get_resp_header/1` - get all response headers, return `Map.t`.
  * `get_resp_header/2` - get response header by `key`, return value.
  * `conn` - `%Conn{}`

  ### Examples

      # {"Cookie", "xyz"}
      %Conn{resp_headers: %{"cookie" => {"Cookie", "xyz"}} |> get_resp_header("cookie")
      # %{"Cookie" => "xyz"}
      %Conn{resp_headers: %{"cookie" => {"Cookie", "xyz"}} |> get_resp_header
  """
  def get_resp_header(conn, key \\ nil)
  def get_resp_header(%Conn{state: :unsent}, _key), do: raise NotSentError
  def get_resp_header(%Conn{resp_headers: headers}, nil) do
    for {_, origin_header} <- headers, into: %{}, do: origin_header
  end
  def get_resp_header(%Conn{resp_headers: headers}, key), do: headers[key] || headers[String.downcase(key)]

  @doc """
  * `get_resp_body/1` - get all response body.
  * `get_resp_body/2` - get response header by `key` or `func`(fn/1).
  * `conn` - `%Conn{}`

  ### Examples

      # "best http client"
      %Conn{resp_body: "best http client" |> get_resp_body
      # "xyz"
      %Conn{resp_body: %{"name" => "xyz"}} |> get_resp_body("name")
      func = fn(x) ->
          [key, value] = String.split(x, ":")
          value
      end
      # "xyz"
      %Conn{resp_body: "name:xyz" |> get_resp_body(func)

  """
  def get_resp_body(conn, func \\ nil)
  def get_resp_body(%Conn{state: :unsent}, _keys), do: raise NotSentError
  def get_resp_body(%Conn{resp_body: body}, nil), do: body
  def get_resp_body(%Conn{resp_body: body}, func)when is_function(func, 1), do: func.(body)
  def get_resp_body(%Conn{resp_body: body}, keys)when is_list(keys), do: get_in(body, keys)
  def get_resp_body(%Conn{resp_body: body}, key), do: body[key]

  @doc """
  Given a partial or full url as a string, returns a Conn struct with the appropriate fields set.
  """
  def parse_url(url) when is_binary(url) do
    uri    = URI.parse(url)
    scheme = uri.scheme || "http"
    path   = uri.path || ""
    conn = case uri do
      %URI{host: nil} ->
        %Conn{path: path}
      %URI{userinfo: nil, port: nil} = uri ->
        %Conn{url: "#{scheme}://#{uri.host}", path: path}
      %URI{userinfo: nil, scheme: "http", port: 80} = uri  ->
        %Conn{url: "#{scheme}://#{uri.host}", path: path}
      %URI{userinfo: nil, scheme: "https", port: 443} = uri  ->
        %Conn{url: "#{scheme}://#{uri.host}", path: path}
      %URI{userinfo: nil, port: port} = uri  ->
        %Conn{url: "#{scheme}://#{uri.host}:#{port}", path: path}
      %URI{userinfo: userinfo, port: port} = uri ->
        %Conn{url: "#{scheme}://#{userinfo}@#{uri.host}:#{port}", path: path}
    end
    case uri.query do
      nil   -> conn
      query -> put_query_string(conn, URI.decode_query(query))
    end
  end

  defimpl Inspect, for: Conn do
    def inspect(conn, opts) do
      Inspect.Any.inspect(conn, opts)
    end
  end

end

