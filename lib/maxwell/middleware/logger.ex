defmodule Maxwell.Middleware.Logger do
  @moduledoc  """
  Log the request
  Log the response
  ```ex
  # Client.ex
  use Maxwell.Builder ~(get)a
  @middleware Maxwell.Middleware.Log [log_level: :info, :log_body_max_len: 500]

  def request do
  "/test" |> url |> get!
  end
  ```
  """
  use Maxwell.Middleware
  require Logger

  def init(opts) do
    check_opts(opts)
    level = Keyword.get(opts, :log_level, :info)
    log_body_max_len = Keyword.get(opts, :log_body_max_len, 500)
    {level, log_body_max_len}
  end

  def call(request_env, next_fn, {level, log_body_max_len}) do
    start_time = :os.timestamp()
    new_result = next_fn.(request_env)
    method = request_env.method |> to_string |> String.upcase
    case new_result do
      {:error, reason} ->
        error_reason = to_string(:io_lib.format("~p", [reason]))
        Logger.log(level, "#{method} #{request_env.url}>> #{IO.ANSI.red}ERROR: " <> error_reason)
      {:ok, response_env} ->
        finish_time = :os.timestamp()
        duration = :timer.now_diff(finish_time, start_time)
        duration_ms = :io_lib.format("~.3f", [duration / 10_000])
        log_response_message(response_env, method, duration_ms, level, log_body_max_len)
    end
    new_result
  end

  defp log_response_message(env, method, ms, level, log_body_max_len) do
    color = case env.status do
              status when status < 300 -> IO.ANSI.green
              status when status < 400 -> IO.ANSI.yellow
              _ -> IO.ANSI.red
            end
    headers = Enum.reduce(env.headers, "", fn({x, y}, acc) -> acc <> "\n#{x}:#{y}" end)
    body_str = case env.body do
             body when is_list(body) or is_binary(body) -> to_string(env.body)
             body -> to_string(:io_lib.format("~p", [body]))
           end
    body_str = String.slice(body_str, 0, log_body_max_len)
    message = "#{method} #{env.url} <<<#{color}#{env.status}(#{ms}ms)#{IO.ANSI.reset}\n<#{headers}\n<#{body_str}"
    Logger.log(level, message)
  end

  defp check_opts(opts) do
    for {key, value} <- opts do
      case key do
        :log_level ->
          unless is_atom(value), do: raise(ArgumentError, "Json Middleware :log_level only accpect atom");
        :log_body_max_len ->
          unless is_integer(value), do: raise(ArgumentError, "Json Middleware :log_body_max_len only accpect integer");
        _ -> raise(ArgumentError, "Logger Middleware Options don't accpect #{key} (:log_body_max_len, :log_level)")
      end
    end
  end

end

