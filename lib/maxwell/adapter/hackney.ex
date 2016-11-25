if Code.ensure_loaded?(:hackney) do
  defmodule Maxwell.Adapter.Hackney do
    @moduledoc  """
    [hackney](https://github.com/benoitc/hackney) adapter
    """

    @doc """
    Receives `%Maxwell.Conn{}`

    Returns `{:ok, %Maxwell.Conn{}}` or `{:error, reason_term}` when synchronous request

    Returns `{:ok, ref_integer}` or `{:error, reason_term}` when asynchronous requests(options add [respond_to: target_self])

    """
    def call(env) do
      env = if target = env.opts[:respond_to] do
        gatherer = spawn_link fn -> receive_response(env, target, nil , nil, nil) end
        opts = env.opts |> List.keyreplace(:respond_to, 0, {:stream_to, gatherer})
        %{env |opts: [:async| opts]}
      else
        env
      end

      env
      |> send_req
      |> format_response(env)
    end

    defp send_req(%Maxwell.Conn{url: url, headers: headers, method: method, opts: opts, body: body}) do
      headers = headers |> Map.to_list
      body = body || ""
      :hackney.request(method, url, headers, body, opts)
    end

    defp format_response({:ok, status, headers, body}, env) when is_binary(body) do
      {:ok, %{env | status:   status,
              headers:  Enum.into(headers, %{}),
              body:     body}}
    end
    defp format_response({:ok, status, headers, body}, env) do
      with {:ok, body} <- :hackney.body(body) do
        {:ok,
         %{env |status:   status,
           headers:  Enum.into(headers, %{}),
           body:     body}}
      end
    end
    defp format_response({:ok, ref}, _env) do
      {:ok, ref}
    end
    defp format_response({:ok, status, headers}, env) do
      format_response({:ok, status, headers, ""}, env)
    end
    defp format_response({:error, _} = error, _env) do
      error
    end

    # todo deal redicrect
    # {:hackney_response, id, {redirect, to, headers}} when redirect in [:redirect, :see_other] ->
    defp receive_response(env, target, status, headers, body) do
      receive do
        {:hackney_response, _id, {:status, new_status, _reason}} ->
          receive_response(env, target, new_status, headers, body)
        {:hackney_response, _id, {:headers, new_headers}} ->
          receive_response(env, target, status, new_headers, body)
        {:hackney_response, _id, {:error, reason}} ->
          send(target, {:maxwell_response, {:error, reason, env}})
        {:hackney_response, _id, :done} ->
          response =
            {:ok, status, headers, body}
            |> format_response(env)
          send(target, {:maxwell_response, response})
        {:hackney_response, _id, append_body} ->
          new_body = if body, do: body <> append_body, else: append_body
          receive_response(env, target, status, headers, new_body)
      end
    end

  end

end

