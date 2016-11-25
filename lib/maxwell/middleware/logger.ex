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
    level = Keyword.get(opts, :log_level, :info)
    log_body_max_len = Keyword.get(opts, :log_body_max_len, 500)
    {level, log_body_max_len}
  end

  def call(request_env, next_fn, {level, log_body_max_len}) do
    start_time = :os.timestamp()
    new_result = next_fn.(request_env)
    case new_result do
      {:error, reason} ->
        error_reason = :io_lib.format("~p", [reason]) |> to_string
        method = request_env.method |> to_string |> String.upcase
        Logger.log(level, "#{method} #{request_env.url} #{IO.ANSI.red}ERROR: " <> error_reason)
      {:ok, response_env} ->
        finish_time = :os.timestamp()
        duration = :timer.now_diff(finish_time, start_time)
        duration_ms = :io_lib.format("~.3f", [duration / 10_000])
        log_response_message(response_env, duration_ms, level, log_body_max_len)
    end
    new_result
  end

  defp log_response_message(env, ms, level, log_body_max_len) do
    method = env.method |> to_string |> String.upcase
    color = case env.status do
              status when status < 300 -> IO.ANSI.green
              status when status < 400 -> IO.ANSI.yellow
              _ -> IO.ANSI.red
            end
    headers = Enum.reduce(env.headers, "", fn({x, y}, acc) -> acc <> "\n#{x}:#{y}" end)
    body = case env.body do
             body when is_list(body) or is_binary(body) -> to_string(env.body)
             body -> :io_lib.format("~p", [body]) |> to_string
           end
           |> String.slice(0, log_body_max_len)
    message = "#{method} #{env.url} <<<#{color}#{env.status}(#{ms}ms)#{IO.ANSI.reset}\n<#{headers}\n<#{body}"
    Logger.log(level, message)
  end

end

