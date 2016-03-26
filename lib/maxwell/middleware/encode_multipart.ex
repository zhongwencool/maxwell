defmodule Maxwell.Middleware.EncodeMultipart do
@moduledoc  """
   # todo
"""
  def call(env, run, _opts) do


   env |> run.()
  end

  def encode_form([], boundary, acc, acc_size) do
   mp_eof = mp_eof(boundary)
   {<< acc::binary, mp_eof::binary>>, acc_size + byte_size(mp_eof)}
  end
  def encode_form([{:file, file}|parts], boundary, acc, acc_size) do
    {mp_header, len} = mp_file_header(file, boundary)
    acc_size = acc_size + byte_size(mp_header) + len + 2
    file_content = File.read!(file.path)
    part = << mp_header::binary, file_content::binary , "\r\n" >>
    acc = << acc::binary, part::binary >>
    encode_form(parts, boundary, acc, acc_size)
  end
  def encode_form([{:mp_mixed, name, mixed_boundary}|parts], boundary, acc, acc_size) do
   {mp_header, _} = mp_mixed_header(name, mixed_boundary)
   acc_size = acc_size + byte_size(mp_header) + 2
   acc = << acc::binary, mp_header::binary, "\r\n" >>
   encode_form(parts, boundary, acc, acc_size)
  end
  def encode_form([{:mp_mixed_eof, mixed_boundary}|parts], boundary, acc, acc_size) do
   eof = mp_eof(mixed_boundary)
   acc_size = acc_size + byte_size(eof) + 2
   acc = << acc::binary, eof::binary, "\r\n" >>
   encode_form(parts, boundary, acc, acc_size)
  end
  def encode_form([{name, data}|parts], boundary, acc, acc_size) do
    bin = data[:binary]
    {mp_header, len} = mp_data_header(name, data, boundary)
    acc_size = acc_size + byte_size(mp_header) + len + 2
    acc = << acc::binary, mp_header::binary, bin::binary, "\r\n" >>
    encode_form(parts, boundary, acc, acc_size)
  end

  defp mp_file_header(file, boundary) do
    path = file[:path]
    file_name = path |> :filename.basename |> to_string
    {disposition, params} =
      unless file[:disposition] do
        {"form-data",
          [{"name", "\"file\""},
           {"filename", << "\"", file_name::binary, "\"" >> }]}
      else
        file[:disposition]
      end

    ctype = :mimerl.filename(path)
    len = :filelib.file_size(path)

    extra_headers = unless file[:extra_headers], do: [], else: file[:extra_headers]
    extra_headers = extra_headers |>  Enum.map(fn({k, v}) -> {String.downcase(k), v} end)
    headers =
      [{"content-disposition", disposition, params} | extra_headers]
      |> List.keystore("content-type", 0, {"content-type", ctype})
      |> List.keystore("content-length", 0, {"content-length", len})
      |> mp_header(boundary)
    {headers, len}
  end

  defp mp_mixed_header(name, boundary) do
    headers =
      [{"Content-Disposition", "form-data", [{"name", << "\"", name::binary, "\"" >>}]},
       {"Content-Type", "multipart/mixed", [{"boundary", boundary}]}
      ]
    {mp_header(headers, boundary), 0}
  end

  defp mp_eof(boundary) do
    << "--",  boundary::binary, "--\r\n" >>
  end

  defp mp_data_header(name, data, boundary) do
    {disposition, params} =
      unless data[:disposition] do
        {"form-data", [{"name", << "\"", name::binary, "\"" >>}]}
      else
        data[:disposition]
      end
    extra_headers = unless data[:extra_headers], do: [], else: data[:extra_headers]
    extra_headers = extra_headers |>  Enum.map(fn({k, v}) -> {String.downcase(k), v} end)
    ctype = :mimerl.filename(name)
    len = byte_size(data[:binary])
    headers =
      [{"content-disposition", disposition, params} | extra_headers]
      |> List.keystore("content-type", 0, {"content-type", ctype})
      |> List.keystore("content-length", 0, {"content-length", len})
      |> mp_header(boundary)
    {headers, len}
  end

  defp mp_header(headers, boundary) do
    headers = to_binary(headers)
    <<"--", boundary::binary, "\r\n", headers::binary >>
  end

  def boundary do
    "---------------------------" <> unique(16)
  end

  defp unique(acc\\"", size)
  defp unique(acc, 0), do: acc
  defp unique(acc, size) do
    random = ?a + :random.uniform(?z - ?a)
    unique(<<acc::binary, random>>, size - 1)
  end

  def to_binary(headers) when is_list(headers) do
    headers =
      headers
      |> Enum.reduce([], fn(header, acc) -> [make_header(header) | acc] end)
      |> Enum.reverse
      |> join("\r\n")
    :erlang.iolist_to_binary([headers, "\r\n\r\n"])
   end

  defp make_header({name, value}) do
    value = value_to_binary(value)
    << name::binary, ": ", value::binary >>
  end
  defp make_header({name, value, params}) do
    value =
      value
      |> value_to_binary
      |> header_value(params)
    << name::binary, ": ", value::binary >>
   end

  defp header_value(value, params) when is_list(value) do
    value
    |> :erlang.list_to_binary
    |> header_value(params)
  end
  defp header_value(value, params) do
    params =
      params
      |> Enum.reduce([],
           fn({k, v}, acc) ->
             k = value_to_binary(k)
             v = value_to_binary(v)
             [<< k::binary, "=", v::binary >> | acc]
           end)
      |> Enum.reverse
    join([value |params] , "; ")
  end

  defp value_to_binary(v) when is_list(v) do
    :erlang.list_to_binary(v)
  end
  defp value_to_binary(v) when is_atom(v) do
    :erlang.atom_to_binary(v, :latin1)
  end
  defp value_to_binary(v) when is_integer(v) do
   "#{v}"
  end
  defp value_to_binary(v) when is_binary(v) do
    v
  end

  defp join([], _Separator), do: ""
  defp join([s], _separator), do: s
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
