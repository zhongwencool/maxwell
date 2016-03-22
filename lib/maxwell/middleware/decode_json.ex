defmodule Maxwell.Middleware.DecodeJson do
  def call(env, run, opts \\ []) do
    decode = opts[:decode] || &Poison.decode/1
    adapter_result = run.(env)
    with {:ok, result} <- adapter_result do
      content_type = result.headers['Content-Type'] || ''
      content_type = content_type |> to_string

      if String.starts_with?(content_type, "application/json") && (is_binary(result.body) || is_list(result.body)) do
        case decode.(to_string(result.body)) do
          {:ok, body}  -> {:ok, %{result | body: body}}
          {:error, reason} -> {:error, {:decode_json_error, reason}}
        end
      else
        adapter_result
      end
    end

  end

end