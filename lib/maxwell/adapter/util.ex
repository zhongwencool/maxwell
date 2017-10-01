defmodule Maxwell.Adapter.Util do
  @moduledoc  """
  Utils for Adapter
  """

  @chunk_size 4 * 1024 * 1024
  alias Maxwell.{Conn, Multipart, Query}

  @doc """
  Append path and query string to url

  * `url`   - `conn.url`
  * `path`  - `conn.path`
  * `query` - `conn.query`
  * `type`  - `:char_list` or `:string`, default is :string

  ### Examples

      #http://example.com/home?name=foo
      iex> url_serialize("http://example.com", "/home", %{"name" => "foo"})

  """
  def url_serialize(url, path, query_string, type \\ :string) do
    url = url |> append_query_string(path, query_string)
    case type do
      :string -> url
      :char_list -> url |> to_charlist
    end
  end

  @doc """
  Converts the headers map to a list of tuples.

     * `headers`   - `Map.t`, for example: `%{"content-type" => "application/json"}`

  ### Examples

       iex> headers_serialize(%{"content-type" => "application/json"})
       [{"content-type", "application/json"}]
  """
  def header_serialize(headers) do
    Enum.into(headers, [])
  end

  @doc """
  Add `content-type` to headers if don't have;
  Add `content-length` to headers if not chunked

     * `chunked`  - `boolean`, is chunked mode
     * `conn`  - `Maxwell.Conn`

  """
  def file_header_transform(chunked, conn) do
    %Conn{req_body: {:file, filepath}, req_headers: req_headers} = conn
    req_headers =
      case Map.has_key?(req_headers, "content-type") do
        true -> req_headers
        false ->
          content_type = :mimerl.filename(filepath)
          conn
          |> Conn.put_req_header("content-type", content_type)
          |> Map.get(:req_headers)
      end
      case chunked or Map.has_key?(req_headers, "content-length") do
        true -> req_headers
        false ->
          len = :filelib.file_size(filepath)
          conn
          |> Conn.put_req_header("content-length", len)
          |> Map.get(:req_headers)
      end
  end

  @doc """
  Check req_headers has transfer-encoding: chunked.

     * `conn`  - `Maxwell.Conn`

  """
  def chunked?(conn) do
    case Conn.get_req_header(conn, "transfer-encoding") do
      nil       -> false
      type      -> "chunked" == String.downcase(type)
    end
  end

  @doc """
  Encode multipart form.

    * `conn`  - `Maxwell.Conn`
    * `multiparts` - see `Maxwell.Multipart.encode_form/2`

  """
  def multipart_encode(conn, multiparts) do
    boundary = Multipart.new_boundary
    body = {&multipart_body/1, {:start, boundary, multiparts}}

    len = Multipart.len_mp_stream(boundary, multiparts)
    headers = conn
    |> Conn.put_req_header("content-type", "multipart/form-data; boundary=#{boundary}")
    |> Conn.put_req_header("content-length", len)
    |> Map.get(:req_headers)

    {headers, body}
  end

  @doc """
  Fetch the first element from stream.

  """
  def stream_iterate(filepath) when is_binary(filepath) do
    filepath
    |> File.stream!([], @chunk_size)
    |> stream_iterate
  end
  def stream_iterate(next_stream_fun) when is_function(next_stream_fun, 1) do
    case next_stream_fun.({:cont, nil}) do
      {:suspended, item, next_stream_fun} -> {:ok, item, next_stream_fun}
      {:halted, _} -> :eof
      {:done, _}   -> :eof
    end
  end
  def stream_iterate(stream) do
    case Enumerable.reduce(stream, {:cont, nil}, fn (item, nil) -> {:suspend, item} end) do
      {:suspended, item, next_stream} -> {:ok, item, next_stream}
      {:done, _}   -> :eof
      {:halted, _} -> :eof
    end
  end

  defp multipart_body({:start, boundary, multiparts}) do
    {body, _size} = Multipart.encode_form(boundary, multiparts)
    {:ok, body, :end}
  end
  defp multipart_body(:end), do: :eof

  defp append_query_string(url, path, query) when query == %{}, do: url <> path
  defp append_query_string(url, path, query) do
    query_string = Query.encode(query)
    url <> path <> "?" <> query_string
  end
end
