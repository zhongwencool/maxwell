defmodule Maxwell.Adapter.Ibrowse do
  def call(env) do
    if target = env.opts[:respond_to] do

      gatherer = spawn_link fn -> gather_response(env, target, nil, nil, nil) end

      opts = env.opts |> List.keyreplace(:respond_to, 0, {:stream_to, gatherer})
      send_req(%{env |opts: opts})
    else
      with {:ok, status, headers, body} <- send_req(env),
           env = format_response(env, status, headers, body),
           do: {:ok, env}
    end
  end

  defp send_req(env) do
    url = env.url |> to_char_list
    headers = env.headers |> Map.to_list
    method = env.method
    opts = env.opts
    body = env.body || []
    case :ibrowse.send_req(url, headers, method, body, opts) do
      {:ibrowse_req_id, id} -> {:ok, id}
      response -> response
    end
  end

  defp gather_response(env, target, status, headers, body) do
    receive do
      {:ibrowse_async_headers, _, new_status, new_headers} ->
        gather_response(env, target, new_status, new_headers, body)

      {:ibrowse_async_response, _, append_body} ->
        new_body = if body, do: body <> append_body, else: append_body
        gather_response(env, target, status, headers, new_body)

      {:ibrowse_async_response_end, _} ->
        response = format_response(env, status, headers, body)
        send target, {:tesla_response, response}
    end
  end

  defp format_response(env, status, headers, body) do
    {status, _} = status |> to_string |> Integer.parse
    headers     = Enum.into(headers, %{})
    %{env | status:   status,
            headers:  headers,
            body:     body}
  end

end
