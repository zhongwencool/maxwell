defmodule Maxwell.Conn do
  @moduledoc """
  The Maxwell connection.

  This module defines a `Maxwell.Conn` struct and the main functions
  for working with Maxwell connections.

  ### Request fields

  These fields contain request information:

     * `url` - the requested url as a binary, example: `"www.example.com:8080/path/?foo=bar"`.
     * `method` - the request method as a atom, example: `GET`.
     * `req_headers` - the request headers as a map, example: `%{"content-type" => "text/plain"}`.
     * `req_body` - the request body, by default is an empty string. It is set
        to nil after the request is set.

  ### Response fields

  These fields contain response information:

     * `status` - the response status
     * `resp_headers` - the response headers as a map.
     * `resp_body` - the response body (todo desc).

  ### Connection fields

     * `state` - the connection state

  The connection state is used to track the connection lifecycle. It starts
  as `:unsent` but is changed to `:sending`, Its final result is `:sent` or `:error`.

  ### Protocols

  `Maxwell.Conn` implements Inspect protocols out of the box.
  The inspect protocol provides a nice representation of the connection.

  """
  @type file_body_t :: {:file, Path.t}
  @type t :: %__MODULE__{
    state: :unsent | :sending | :sent | :error,
    method: atom,
    url: String.t,
    path: String.t,
    query_string: map,
    opts: Keyword.t,
    req_headers: %{binary => binary},
    req_body: iodata | map | Maxwell.Multipart.t | file_body_t | Enumerable.t,
    status: non_neg_integer | nil,
    resp_headers: %{binary => binary},
    resp_body: iodata | map,
    private: map
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
    resp_body: "",
    private: %{}

  alias Maxwell.{Conn, Query}

  defmodule AlreadySentError do
    @moduledoc """
    Error raised when trying to modify or send an already sent request
    """
    defexception message: "the request was already sent"
  end

  defmodule NotSentError do
    @moduledoc """
    Error raised when no request is sent in a connection
    """
    defexception message: "the request was not sent yet"
  end

  @doc """
  Create a new connection.
  The url provided will be parsed by `URI.parse/1`, and the relevant connection fields will
  be set accordingly.

  ### Examples

      iex> new()
      %Maxwell.Conn{}

      iex> new("http://example.com/foo")
      %Maxwell.Conn{url: "http://example.com", path: "/foo"}

      iex> new("http://example.com/foo?bar=qux")
      %Maxwell.Conn{url: "http://example.com", path: "/foo", query_string: %{"bar" => "qux"}}
  """
  @spec new() :: t
  def new(), do: %Conn{}
  @spec new(binary) :: t
  def new(url) when is_binary(url) do
    %URI{scheme: scheme, path: path, query: query} = uri = URI.parse(url)
    scheme = scheme || "http"
    path   = path || ""
    conn = case uri do
             %URI{host: nil} ->
               # This is a badly formed URI, so we'll do best effort:
               cond do
                 # example.com:8080
                 scheme != nil and Integer.parse(path) != :error ->
                   %Conn{url: "http://#{scheme}:#{path}"}
                 String.contains?(path, ".") -> # example.com
                   %Conn{url: "#{scheme}://#{path}"}
                 path == "localhost" -> # special case for localhost
                   %Conn{url: "#{scheme}://localhost"}
                 String.starts_with?(path, "/") -> # /example - not a valid hostname, assume it's a path
                   %Conn{path: path}
                 true -> # example - not a valid hostname, assume it's a path
                   %Conn{path: "/" <> path}
               end
             %URI{userinfo: nil, scheme: "http", port: 80, host: host} ->
               %Conn{url: "http://#{host}", path: path}
             %URI{userinfo: nil, scheme: "https", port: 443, host: host} ->
               %Conn{url: "https://#{host}", path: path}
             %URI{userinfo: nil, port: port, host: host} ->
               %Conn{url: "#{scheme}://#{host}:#{port}", path: path}
             %URI{userinfo: userinfo, port: port, host: host} ->
               %Conn{url: "#{scheme}://#{userinfo}@#{host}:#{port}", path: path}
           end
    case is_nil(query) do
      true   -> conn
      false -> put_query_string(conn, Query.decode(query))
    end
  end

  @doc """
  Set the path of the request.

  ### Examples

       iex> put_path(new(), "delete")
       %Maxwell.Conn{path: "delete"}
  """
  @spec put_path(t, String.t) :: t | no_return
  def put_path(%Conn{state: :unsent} = conn, path), do: %{conn | path: path}
  def put_path(_conn, _path), do: raise AlreadySentError

  @doc false
  def put_path(path) when is_binary(path) do
    IO.warn "put_path/1 is deprecated, use new/1 or new/2 followed by put_path/2 instead"
    put_path(new(), path)
  end

  @doc """
  Add query string to `conn.query_string`.

    * `conn` - `%Conn{}`
    * `query_map` - as map, for example `%{foo => bar}`

  ### Examples

      # %Conn{query_string: %{name: "zhong wen"}}
      put_query_string(%Conn{}, %{name: "zhong wen"})

  """
  @spec put_query_string(t, map()) :: t | no_return
  def put_query_string(%Conn{state: :unsent, query_string: qs} = conn, query) do
    %{conn | query_string: Map.merge(qs, query)}
  end
  def put_query_string(_conn, _query_map), do: raise AlreadySentError

  @doc false
  def put_query_string(query) when is_map(query) do
    IO.warn "put_query_string/1 is deprecated, use new/1 or new/2 followed by put_query_string/2 instead"
    put_query_string(new(), query)
  end

  @doc """
  Set a query string value for the request.

  ### Examples

        iex> put_query_string(new(), :name, "zhong wen")
        %Maxwell.Conn{query_string: %{:name => "zhong wen"}}
  """
  def put_query_string(%Conn{state: :unsent, query_string: qs} = conn, key, value) do
    %{conn | query_string: Map.put(qs, key, value)}
  end
  def put_query_string(_conn, _key, _value), do: raise AlreadySentError

  @doc """
  Merge a map of headers into the existing headers of the connection.

  ### Examples

      iex> %Maxwell.Conn{headers: %{"content-type" => "text/javascript"}
      |> put_req_headers(%{"Accept" => "application/json"})
      %Maxwell.Conn{req_headers: %{"accept" => "application/json", "content-type" => "text/javascript"}}
  """
  @spec put_req_headers(t, map()) :: t | no_return
  def put_req_headers(%Conn{state: :unsent, req_headers: headers} = conn, extra_headers) when is_map(extra_headers) do
    new_headers =
    extra_headers
    |> Enum.reduce(headers, fn {header_name, header_value}, acc ->
      Map.put(acc, String.downcase(header_name), header_value)
    end)
    %{conn | req_headers: new_headers}
  end
  def put_req_headers(_conn, _headers), do: raise AlreadySentError

  # TODO: Remove
  @doc false
  def put_req_header(headers) do
    IO.warn "put_req_header/1 is deprecated, use new/1 or new/2 followed by put_req_headers/2 instead"
    put_req_headers(new(), headers)
  end

  # TODO: Remove
  @doc false
  def put_req_header(conn, headers) when is_map(headers) do
    IO.warn "put_req_header/2 is deprecated, use put_req_headers/1 instead"
    put_req_headers(conn, headers)
  end

  @doc """
  Set a request header. If it already exists, it is updated.

  ### Examples

      iex> %Maxwell.Conn{req_headers: %{"content-type" => "text/javascript"}}
      |> put_req_header("Content-Type", "application/json")
      |> put_req_header("User-Agent", "zhongwencool")
      %Maxwell.Conn{req_headers: %{"content-type" => "application/json", "user-agent" => "zhongwenool"}
  """
  def put_req_header(%Conn{state: :unsent, req_headers: headers} = conn, key, value) do
    new_headers = Map.put(headers, String.downcase(key), value)
    %{conn | req_headers: new_headers}
  end
  def put_req_header(_conn, _key, _value), do: raise AlreadySentError

  @doc """
  Get all request headers as a map

  ### Examples

      iex> %Maxwell.Conn{req_headers: %{"cookie" => "xyz"} |> get_req_header
      %{"cookie" => "xyz"}
  """
  @spec get_req_header(t) :: %{String.t => String.t}
  def get_req_headers(%Conn{req_headers: headers}), do: headers

  # TODO: Remove
  @doc false
  def get_req_header(conn) do
    IO.warn "get_req_header/1 is deprecated, use get_req_headers/1 instead"
    get_req_headers(conn)
  end

  @doc """
  Get a request header by key. The key lookup is case-insensitive.
  Returns the value as a string, or nil if it doesn't exist.

  ### Examples

      iex> %Maxwell.Conn{req_headers: %{"cookie" => "xyz"} |> get_req_header("cookie")
      "xyz"
  """
  @spec get_req_header(t, String.t) :: String.t | nil
  def get_req_header(conn, nil) do
    IO.warn "get_req_header/2 with a nil key is deprecated, use get_req_headers/2 instead"
    get_req_headers(conn)
  end
  def get_req_header(%Conn{req_headers: headers}, key), do: Map.get(headers, String.downcase(key))

  @doc """
  Set adapter options for the request.

  ### Examples

      iex> put_options(new(), connect_timeout: 4000)
      %Maxwell.Conn{opts: [connect_timeout: 4000]}
  """
  @spec put_options(t, Keyword.t) :: t | no_return
  def put_options(%Conn{state: :unsent, opts: opts} = conn, extra_opts) when is_list(extra_opts) do
    %{conn | opts: Keyword.merge(opts, extra_opts)}
  end
  def put_options(_conn, extra_opts) when is_list(extra_opts), do: raise AlreadySentError

  @doc """
  Set an adapter option for the request.

  ### Examples

      iex> put_option(new(), :connect_timeout, 5000)
      %Maxwell.Conn{opts: [connect_timeout: 5000]}
  """
  @spec put_option(t, atom(), term()) :: t | no_return
  def put_option(%Conn{state: :unsent, opts: opts} = conn, key, value) when is_atom(key) do
    %{conn | opts: [{key, value} | opts]}
  end
  def put_option(%Conn{}, key, _value) when is_atom(key), do: raise AlreadySentError

  # TODO: remove
  @doc false
  def put_option(opts) when is_list(opts) do
    IO.warn "put_option/1 is deprecated, use new/1 or new/2 followed by put_options/2 instead"
    put_options(new(), opts)
  end

  # TODO: remove
  @doc false
  def put_option(conn, opts) when is_list(opts) do
    IO.warn "put_option/2 is deprecated, use put_options/2 instead"
    put_options(conn, opts)
  end

  @doc """
  Set the request body.

  ### Examples

      iex> put_req_body(new(), "new body")
      %Maxwell.Conn{req_body: "new_body"}
  """
  @spec put_req_body(t, Enumerable.t | binary()) :: t | no_return
  def put_req_body(%Conn{state: :unsent} = conn, req_body) do
    %{conn | req_body: req_body}
  end
  def put_req_body(_conn, _req_body), do: raise AlreadySentError

  # TODO: remove
  @doc false
  def put_req_body(body) do
    IO.warn "put_req_body/1 is deprecated, use new/1 or new/2 followed by put_req_body/2 instead"
    put_req_body(new(), body)
  end

  @doc """
  Get response status.
  Raises `Maxwell.Conn.NotSentError` when the request is unsent.

  ### Examples

      iex> get_status(%Maxwell.Conn{status: 200})
      200
  """
  @spec get_status(t) :: pos_integer | no_return
  def get_status(%Conn{status: status, state: state}) when state !== :unsent, do: status
  def get_status(_conn), do: raise NotSentError

  @doc """
  Get all response headers as a map.

  ### Examples

      iex> %Maxwell.Conn{resp_headers: %{"cookie" => "xyz"} |> get_resp_header
      %{"cookie" => "xyz"}
  """
  @spec get_resp_headers(t) :: %{String.t => String.t} | no_return
  def get_resp_headers(%Conn{state: :unsent}), do: raise NotSentError
  def get_resp_headers(%Conn{resp_headers: headers}), do: headers

  # TODO: remove
  @doc false
  def get_resp_header(conn) do
    IO.warn "get_resp_header/1 is deprecated, use get_resp_headers/1 instead"
    get_resp_headers(conn)
  end

  @doc """
  Get a response header by key.
  The value is returned as a string, or nil if the header is not set.

  ### Examples

      iex> %Maxwell.Conn{resp_headers: %{"cookie" => "xyz"}} |> get_resp_header("cookie")
      "xyz"
  """
  @spec get_resp_header(t, String.t) :: String.t | nil | no_return
  def get_resp_header(%Conn{state: :unsent}, _key), do: raise NotSentError
  # TODO: remove
  def get_resp_header(conn, nil) do
    IO.warn "get_resp_header/2 with a nil key is deprecated, use get_resp_headers/1 instead"
    get_resp_headers(conn)
  end
  def get_resp_header(%Conn{resp_headers: headers}, key), do: Map.get(headers, String.downcase(key))

  @doc """
  Return the response body.

  ### Examples

      iex> get_resp_body(%Maxwell.Conn{state: :sent, resp_body: "best http client"})
      "best http client"
  """
  @spec get_resp_body(t) :: binary() | map() | no_return
  def get_resp_body(%Conn{state: :sent, resp_body: body}), do: body
  def get_resp_body(_conn), do: raise NotSentError

  @doc """
  Return a value from the response body by key or with a parsing function.

  ### Examples

      iex> get_resp_body(%Maxwell.Conn{state: :sent, resp_body: %{"name" => "xyz"}}, "name")
      "xyz"

      iex> func = fn(x) ->
      ...>   [key, value] = String.split(x, ":")
      ...>   value
      ...> end
      ...> get_resp_body(%Maxwell.Conn{state: :sent, resp_body: "name:xyz"}, func)
      "xyz"
  """
  def get_resp_body(%Conn{state: state}, _) when state != :sent,             do: raise NotSentError
  def get_resp_body(%Conn{resp_body: body}, func) when is_function(func, 1), do: func.(body)
  def get_resp_body(%Conn{resp_body: body}, keys) when is_list(keys),        do: get_in(body, keys)
  def get_resp_body(%Conn{resp_body: body}, key), do: body[key]


  @doc """
  Set a private value. If it already exists, it is updated.

  ### Examples

      iex> %Maxwell.Conn{private: %{}}
      |> put_private(:user_id, "zhongwencool")
      %Maxwell.Conn{private: %{user_id: "zhongwencool"}}
  """
  @spec put_private(t, atom, term()) :: t
  def put_private(%Conn{private: private} = conn, key, value) do
    new_private = Map.put(private, key, value)
    %{conn | private: new_private}
  end

  @doc """
  Get a private value

  ### Examples

      iex> %Maxwell.Conn{private: %{user_id: "zhongwencool"}}
      |> get_private(:user_id)
      "zhongwencool"
  """
  @spec get_private(t, atom) :: term()
  def get_private(%Conn{private: private}, key) do
    Map.get(private, key)
  end

  defimpl Inspect, for: Conn do
    def inspect(conn, opts) do
      Inspect.Any.inspect(conn, opts)
    end
  end
end
