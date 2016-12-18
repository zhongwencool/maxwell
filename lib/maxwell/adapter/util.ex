defmodule Maxwell.Adapter.Util do
  @moduledoc  """
  Utils for Adapter
  """

  @chunk_size 4 * 1024 * 1024
  alias Maxwell.Conn
  alias Maxwell.Multipart

  @doc """
  Append path and query string to url,
  query string encode by `URI.encode_query/1`.

  * `url`   - `conn.url`
  * `path`  - `conn.path`
  * `query` - `conn.query`
  * `type`  - `:char_list` or `:string`, default is :string

  ### Examples

  # http://example.com/home?name=foo
  iex> url_serialize("http://example.com", "/home", %{"name" => "foo"})
  """
  def url_serialize(url, path, query_string, type \\ :string) do
    url = url |> append_query_string(path, query_string)
    case type do
      :string -> url
      :char_list -> url |> to_char_list
    end
  end

  def header_serialize(headers) do
    headers |> Map.values
  end

  def file_header_serialize(chunked, conn, req_headers) do
    %Conn{req_body: {:file, filepath}} = conn
    req_headers =
      case Map.has_key?(req_headers, "content-type") do
        true -> req_headers
        false ->
          content_type = :mimerl.filename(filepath)
          conn
          |> Conn.put_req_header("content-type", content_type)
          |> Map.get(:req_headers)
      end
    req_headers =
      case chunked or Map.has_key?(req_headers, "content-length") do
        true -> req_headers
        false ->
          len = :filelib.file_size(filepath)
          conn
          |> Conn.put_req_header("content-length", len)
          |> Map.get(:req_headers)
      end
    req_headers |> header_serialize
  end

  def chunked?(conn) do
    case Conn.get_req_header(conn, "transfer-encoding") do
      {_, "chunked"} -> true
      {_, type} -> "chunked" == String.downcase(type)
      nil -> false
    end
  end

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

  def multipart_body({:start, boundary, multiparts}) do
    {body, _size} = Multipart.encode_form(boundary, multiparts)
    {:ok, body, :end}
  end
  def multipart_body(:end), do: :eof

  def stream_iterate(filepath) when is_binary(filepath) do
    filepath
    |> File.stream!([], @chunk_size)
    |> stream_iterate
  end
  def stream_iterate(next_stream_fun)when is_function(next_stream_fun, 1) do
    case next_stream_fun.({:cont, nil}) do
      {:suspended, item, next_stream_fun} -> {:ok, item, next_stream_fun}
      {:halted, _} -> :eof
      {:done, _} -> :eof
    end
  end
  def stream_iterate(stream) do
		case Enumerable.reduce(stream, {:cont, nil}, fn(item, nil)-> {:suspend, item} end) do
      {:suspended, item, next_stream} -> {:ok, item, next_stream}
			{:done, _} -> :eof
      {:halted, _} -> :eof
		end
  end

  defp append_query_string(url, path, query)when query == %{}, do: url <> path
  defp append_query_string(url, path, query) do
    query_string = URI.encode_query(query)
    url <> path <> "?" <> query_string
  end
end
