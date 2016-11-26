defmodule Maxwell.Multipart do
@moduledoc  """
  Process mutipart for adapter
"""
  @doc """
   Receives lists list's member format:
    1. `{:file, path}`
    2. `{:file, path, extra_headers}`
    3. `{:file, path, disposition, extra_headers}`
    4. `{:mp_mixed, name, mixed_boundary}`
    5. `{:mp_mixed_eof, mixed_boundary}`
    6. `{name, bin_data}`
    7. `{name, bin_data, extra_headers}`
    8. `{name, bin_data, disposition, extra_headers}`

  Returns `{body_binary, size}`

  """
  @eof_size 2

  def encode(parts), do: encode(new_boundary, parts)
  def encode(boundary, parts)when is_list(parts) do
    encode_form(parts, boundary, "", 0)
  end

  @doc """
   Return a random boundary(binary)

   ```
     "---------------------------mtynipxrmpegseog"
   ```
  """
  def new_boundary, do: "---------------------------" <> unique(16)

  @doc """
   Get the size of a mp stream. Useful to calculate the content-length of a full multipart stream and send it as an identity

   Receives parameter as `Maxwell.Multipart.encode`

   Return stream size(integer)
  """
  def len_mp_stream(boundary, parts) do
    size =
      Enum.reduce(parts, 0,
        fn({:file, path}, acc_size) ->
            {mp_header, len} = mp_file_header(%{path: path}, boundary)
            acc_size + byte_size(mp_header) + len + @eof_size
          ({:file, path, extra_headers}, acc_size) ->
            {mp_header, len} = mp_file_header(%{path: path, extra_headers: extra_headers}, boundary)
            acc_size + byte_size(mp_header) + len + @eof_size
          ({:file, path, disposition, extra_headers}, acc_size) ->
            file = %{path: path, extra_headers: extra_headers, disposition: disposition}
            {mp_header, len} = mp_file_header(file, boundary)
            acc_size + byte_size(mp_header) + len + @eof_size
          ({:mp_mixed, name, mixed_boundary}, acc_size) ->
            {mp_header, _} = mp_mixed_header(name, mixed_boundary)
            acc_size + byte_size(mp_header) + @eof_size + byte_size(mp_eof(mixed_boundary))
          ({:mp_mixed_eof, mixed_boundary}, acc_size) ->
            acc_size + byte_size(mp_eof(mixed_boundary)) + @eof_size
          ({name, bin}, acc_size) when is_binary(bin) ->
            {mp_header, len} = mp_data_header(name, %{binary: bin}, boundary)
            acc_size + byte_size(mp_header) + len + @eof_size
          ({name, bin, extra_headers}, acc_size) when is_binary(bin) ->
            {mp_header, len} = mp_data_header(name, %{binary: bin, extra_headers: extra_headers}, boundary)
            acc_size + byte_size(mp_header) + len + @eof_size
          ({name, bin, disposition, extra_headers}, acc_size) when is_binary(bin) ->
            data = %{binary: bin, disposition: disposition, extra_headers: extra_headers}
            {mp_header, len} = mp_data_header(name, data, boundary)
            acc_size + byte_size(mp_header) + len + @eof_size
        end)
    size + byte_size(mp_eof(boundary))
  end

  defp encode_form([], boundary, acc, acc_size) do
   mp_eof = mp_eof(boundary)
   {acc <> mp_eof, acc_size + byte_size(mp_eof)}
  end
  defp encode_form([{:file, path}|parts], boundary, acc, acc_size) do
    {mp_header, len} = mp_file_header(%{path: path}, boundary)
    acc_size = acc_size + byte_size(mp_header) + len + @eof_size
    file_content = File.read!(path)
    acc = acc <> mp_header <> file_content <> "\r\n"
    encode_form(parts, boundary, acc, acc_size)
  end
  defp encode_form([{:file, path, extra_headers}|parts], boundary, acc, acc_size) do
    file = %{path: path, extra_headers: extra_headers}
    {mp_header, len} = mp_file_header(file, boundary)
    acc_size = acc_size + byte_size(mp_header) + len + @eof_size
    file_content = File.read!(path)
    acc = acc <> mp_header <> file_content <> "\r\n"
    encode_form(parts, boundary, acc, acc_size)
  end
  defp encode_form([{:file, path, disposition, extra_headers}|parts], boundary, acc, acc_size) do
    file = %{path: path, extra_headers: extra_headers, disposition: disposition}
    {mp_header, len} = mp_file_header(file, boundary)
    acc_size = acc_size + byte_size(mp_header) + len + @eof_size
    file_content = File.read!(path)
    acc = acc <> mp_header <> file_content <> "\r\n"
    encode_form(parts, boundary, acc, acc_size)
  end

  defp encode_form([{:mp_mixed, name, mixed_boundary}|parts], boundary, acc, acc_size) do
   {mp_header, _} = mp_mixed_header(name, mixed_boundary)
   acc_size = acc_size + byte_size(mp_header) + @eof_size
   acc = acc <> mp_header <> "\r\n"
   encode_form(parts, boundary, acc, acc_size)
  end
  defp encode_form([{:mp_mixed_eof, mixed_boundary}|parts], boundary, acc, acc_size) do
   eof = mp_eof(mixed_boundary)
   acc_size = acc_size + byte_size(eof) + @eof_size
   acc = acc <> eof <> "\r\n"
   encode_form(parts, boundary, acc, acc_size)
  end

  defp encode_form([{name, bin}|parts], boundary, acc, acc_size) do
    {mp_header, len} = mp_data_header(name, %{binary: bin}, boundary)
    acc_size = acc_size + byte_size(mp_header) + len + @eof_size
    acc = acc <> mp_header <> bin <> "\r\n"
    encode_form(parts, boundary, acc, acc_size)
  end
  defp encode_form([{name, bin, extra_headers}|parts], boundary, acc, acc_size) do
    {mp_header, len} = mp_data_header(name, %{binary: bin, extra_headers: extra_headers}, boundary)
    acc_size = acc_size + byte_size(mp_header) + len + @eof_size
    acc = acc <> mp_header <> bin <> "\r\n"
    encode_form(parts, boundary, acc, acc_size)
  end
  defp encode_form([{name, bin, disposition, extra_headers}|parts], boundary, acc, acc_size) do
    data = %{binary: bin, extra_headers: extra_headers, disposition: disposition}
    {mp_header, len} = mp_data_header(name, data, boundary)
    acc_size = acc_size + byte_size(mp_header) + len + @eof_size
    acc = acc <> mp_header <> bin <> "\r\n"
    encode_form(parts, boundary, acc, acc_size)
  end

  defp mp_file_header(file, boundary) do
    path = file[:path]
    file_name = path |> :filename.basename |> to_string
    {disposition, params} = file[:disposition] || {"form-data", [{"name", "\"file\""}, {"filename", "\"" <> file_name <> "\""}]}
    ctype = :mimerl.filename(path)
    len = :filelib.file_size(path)

    extra_headers = file[:extra_headers] || []
    extra_headers = extra_headers |>  Enum.map(fn({k, v}) -> {String.downcase(k), v} end)

    headers =
      [{"content-length", len}, {"content-disposition", disposition, params}, {"content-type", ctype}]
      |> replace_header_from_extra(extra_headers)
      |> mp_header(boundary)

    {headers, len}
  end

  defp mp_mixed_header(name, boundary) do
    headers =
      [{"Content-Disposition", "form-data", [{"name", "\"" <> name <> "\""}]},
       {"Content-Type", "multipart/mixed", [{"boundary", boundary}]}
      ]
    {mp_header(headers, boundary), 0}
  end

  defp mp_eof(boundary), do: "--" <>  boundary <> "--\r\n"

  defp mp_data_header(name, data, boundary) do
    {disposition, params} = data[:disposition] || {"form-data", [{"name", "\"" <> name <> "\""}]}
    extra_headers = data[:extra_headers] || []
    extra_headers = extra_headers |>  Enum.map(fn({k, v}) -> {String.downcase(k), v} end)
    ctype = :mimerl.filename(name)
    len = byte_size(data[:binary])
    headers =
      [{"content-length", len}, {"content-type", ctype}, {"content-disposition", disposition, params}]
      |> replace_header_from_extra(extra_headers)
      |> mp_header(boundary)
    {headers, len}
  end

  defp mp_header(headers, boundary), do: "--" <> boundary <> "\r\n" <> (headers_to_binary(headers))

  defp unique(size, acc \\ [])
  defp unique(0, acc), do: acc |> :erlang.list_to_binary
  defp unique(size, acc) do
    random = Enum.random(?a..?z)
    unique(size - 1, [random | acc])
  end

  defp headers_to_binary(headers) when is_list(headers) do
    headers =
      headers
      |> Enum.reduce([], fn(header, acc) -> [make_header(header) | acc] end)
      |> Enum.reverse
      |> join("\r\n")
    :erlang.iolist_to_binary([headers, "\r\n\r\n"])
   end

  defp make_header({name, value}) do
    value = value_to_binary(value)
    name <> ": " <> value
  end
  defp make_header({name, value, params}) do
    value =
      value
      |> value_to_binary
      |> header_value(params)
    name <> ": " <> value
   end

  defp header_value(value, params) do
    params =
      params
      |> Enum.reduce([],
           fn({k, v}, acc) ->
             k = value_to_binary(k)
             v = value_to_binary(v)
             [k <> "=" <> v | acc]
           end)
      |> Enum.reverse
    join([value |params] , "; ")
  end

  defp replace_header_from_extra(headers, extra_headers) do
    extra_headers
    |> Enum.reduce(headers, fn({ex_header, ex_value}, acc) ->
         case List.keymember?(acc, ex_header, 0) do
           true ->  List.keyreplace(acc, ex_header, 0, {ex_header, ex_value})
           false -> [{ex_header, ex_value} |acc]
         end
      end)
  end

  defp value_to_binary(v) when is_list(v) do
    :binary.list_to_bin(v)
  end
  defp value_to_binary(v) when is_atom(v) do
    :erlang.atom_to_binary(v, :latin1)
  end
  defp value_to_binary(v) when is_integer(v) do
   Integer.to_string v
  end
  defp value_to_binary(v) when is_binary(v) do
    v
  end

  defp join([], _Separator), do: ""
  # defp join([s], _separator), do: s
  defp join(l, separator) do
   l
   |> Enum.reverse
   |> join(separator, [])
   |> :erlang.iolist_to_binary
  end
  defp join([], _separator, acc), do: acc
  defp join([s | rest], separator, []), do: join(rest, separator, [s])
  defp join([s | rest], separator, acc), do: join(rest, separator, [s, separator | acc])

end
