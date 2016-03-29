defmodule Maxwell.Adapter.Ibrowse do
@moduledoc  """
  [ibrowse](https://github.com/cmullaparthi/ibrowse) adapter
  """

  @doc """
    Receives `%Maxwell{}`

    Returns `{:ok, %Maxwell{}}` or `{:error, reason_term}` when synchronous request

    Returns `{:ok, ref_integer}` when asynchronous requests(options add [respond_to: target_self])

  """
  def call(env) do
    if target = env.opts[:respond_to] do
      gatherer = spawn_link fn -> receive_response(env, target, nil, nil, nil) end
      opts = env.opts |> List.keyreplace(:respond_to, 0, {:stream_to, gatherer})
      env = %{env |opts: opts}
    end

    env
    |> send_req
    |> format_response(env)
  end

  defp send_req(%Maxwell{url: url, headers: headers, method: method, opts: opts, body: body}) do
    url = url |> to_char_list
    headers = headers |> Map.to_list
    {headers, body} = need_multipart_encode(headers, body)
    :ibrowse.send_req(url, headers, method, body, opts)
  end

  defp receive_response(env, target, status, headers, body) do
    receive do
      {:ibrowse_async_headers, _, new_status, new_headers} ->
        receive_response(env, target, new_status, new_headers, body)

      {:ibrowse_async_response, _, append_body} ->
        new_body = if body, do: body <> append_body, else: append_body
        receive_response(env, target, status, headers, new_body)

      {:ibrowse_async_response_end, _} ->
        response = format_response({:ok, status, headers, body}, env)
        send(target, {:maxwell_response, response})
    end
  end

  defp format_response({:ibrowse_req_id, id}, _env), do: {:ok, id}
  defp format_response({:ok, status, headers, body}, env) do
    {status, _} = status |> to_string |> Integer.parse
    headers     = Enum.into(headers, %{})
    {:ok, %{env |status:   status,
                 headers:  headers,
                 body:     body}
    }
  end
  defp format_response({:error, _} = error, _env) do
    error
  end

  defp need_multipart_encode(headers, {:multipart, multipart}) do
    boundary = Maxwell.Multipart.boundary
    body =
      {fn(true) ->
           {body, _size} = Maxwell.Multipart.encode(boundary, multipart)
           {:ok, body, false}
         (false) -> :eof
       end, true}
    len = Maxwell.Multipart.len_mp_stream(boundary, multipart)
    headers = [{'Content-Type', "multipart/form-data; boundary=#{boundary}"}, {'Content-Length', len}|headers]
    {headers, body}
  end
  defp need_multipart_encode(headers, body), do: {headers, body || []}

end
