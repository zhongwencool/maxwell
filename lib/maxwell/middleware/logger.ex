defmodule Maxwell.Middleware.Logger do
  @moduledoc  """
  Log the request and response by Logger, default log_level is :info.

  ### Examples

        # Client.ex
        use Maxwell.Builder ~(get)a
        @middleware Maxwell.Middleware.Log [log_level: :debug]

        def request do
          "/test" |> url |> get!
        end

  """
  use Maxwell.Middleware
  require Logger

  def init(opts) do
    check_opts(opts)
    Keyword.get(opts, :log_level, :info)
  end

  def call(request_env, next_fn, level) do
    start_time = :os.timestamp()
    new_result = next_fn.(request_env)
    method = request_env.method |> to_string |> String.upcase
    case new_result do
      {:error, reason} ->
        error_reason = to_string(:io_lib.format("~p", [reason]))
        Logger.log(level, "#{method} #{request_env.url}>> #{IO.ANSI.red}ERROR: " <> error_reason)
      {:ok, response_conn} ->
        finish_time = :os.timestamp()
        duration = :timer.now_diff(finish_time, start_time)
        duration_ms = :io_lib.format("~.3f", [duration / 10_000])
        log_response_message(response_conn, duration_ms, level)
    end
    new_result
  end

  defp log_response_message(conn, ms, level) do
    %Maxwell.Conn{status: status, url: url, method: method} = conn
    color = case status do
              _ when status < 300 -> IO.ANSI.green
              _ when status < 400 -> IO.ANSI.yellow
              _ -> IO.ANSI.red
            end
    message = "#{method} #{url} <<<#{color}#{status}(#{ms}ms)#{IO.ANSI.reset}\n#{inspect conn}"
    Logger.log(level, message)
  end

  defp check_opts(opts) do
    for {key, value} <- opts do
      case key do
        :log_level ->
          unless is_atom(value), do: raise(ArgumentError, "Logger Middleware :log_level only accpect atom");
        _ -> raise(ArgumentError, "Logger Middleware Options don't accpect #{key} (:log_level)")
      end
    end
  end

end

