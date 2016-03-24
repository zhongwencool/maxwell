defmodule Maxwell.Adapter.Hackney do
@moduledoc  """
  [hackney](https://github.com/benoitc/hackney) adapter
  """

  @doc """
    Receives `%Maxwell{}`

    Returns `{:ok, %Maxwell{}}` or `{:error, reason_term}` when synchronous request

    Returns `{:ok, id_integer}` when asynchronous requests(options add [respond_to: target_self])

  """
  def call(env) do
    if target = env.opts[:respond_to] do

      gatherer = spawn_link fn -> gather_response(env, target, nil, nil, nil) end

      opts = env.opts |> List.keyreplace(:respond_to, 0, {:stream_to, gatherer})
      env = %{env |opts: [:async| opts]}
      send_req(env)
    else
      send_req(env)
      |> format_response(env)
    end
  end

  defp send_req(env) do
    url = env.url
    headers = env.headers |> Map.to_list
    method = env.method
    opts = env.opts
    body = env.body || []
    :hackney.request(method, url, headers, body, opts)
  end

# todo deal redicrect
# {:hackney_response, id, {redirect, to, headers}} when redirect in [:redirect, :see_other] ->
  defp gather_response(env, target, status, headers, body) do
    receive do
      {:hackney_response, _id, {:status, new_status, _reason}} ->
        gather_response(env, target, new_status, headers, body)
      {:hackney_response, _id, {:headers, new_headers}} ->
        gather_response(env, target, status, new_headers, body)
      {:hackney_response, _id, {:error, _reason} = error} ->
        send target, {:maxwell_response, error}
      {:hackney_response, _id, :done} ->
        response = format_response({:ok, status, headers, body}, env)
        send target, {:maxwell_response, response}
      {:hackney_response, _id, append_body} ->
        new_body = if body, do: body <> append_body, else: append_body
        gather_response(env, target, status, headers, new_body)
    end
  end

  defp format_response({:ok, status, headers, body}, env) do
    headers     = Enum.into(headers, %{})
    case :hackney.body(body) do
      {:ok, body} ->
        {:ok, %{env | status:   status,
                      headers:  headers,
                      body:     body}}
      {:error, _} = reason ->
        reason
      end
  end
  defp format_response({:ok, status, headers}, env) do
    format_response({:ok, status, headers, ""}, env)
  end
  defp format_response({:ok, id}, _env) do
    {:ok, id}
  end
  defp format_response({:error, _} = error, _env) do
    error
  end

end
