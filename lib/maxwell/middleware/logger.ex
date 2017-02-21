defmodule Maxwell.Middleware.Logger do
  @moduledoc  """
  Log the request and response by Logger, default log_level is :info.
  Setting log_level in 3 ways:

  ### Log everything by log_level

      middleware Maxwell.Middleware.Logger, log_level: :debug

  ### Log request by specific status code.

      middleware Maxwell.Middleware.Logger, log_level: [debug: 200, error: 404, info: default]

  ### Log request by status code's Ranges

      middleware Maxwell.Middleware.Logger, log_level: [error: [500..599, 300..399, 400], warn: 404, debug: default]

  ### Examples

        # Client.ex
        use Maxwell.Builder ~(get)a

        middleware Maxwell.Middleware.Logger, log_level: [
          info: [1..100, 200..299, 404],
          warn: 300..399,
          error: :default
        ]

        def your_own_request(url) do
          url |> new() |> get!()
        end

  """
  use Maxwell.Middleware
  require Logger

  @levels [:info, :debug, :warn, :error]

  def init(opts) do
    case Keyword.pop(opts, :log_level) do
      {_, [_|_]} ->
        raise ArgumentError, "Logger Middleware Options doesn't accept wrong_option (:log_level)"
      {nil, _}                           -> [default: :info]
      {options, _} when is_list(options) -> parse_opts(options)
      {level, _}                         -> parse_opts([{level, :default}])
    end
  end

  def call(request_env, next_fn, options) do
    start = System.system_time(:milliseconds)
    new_result = next_fn.(request_env)
    case new_result do
      {:error, reason, _conn} ->
        method = request_env.method |> to_string |> String.upcase
        Logger.error("#{method} #{request_env.url}>> #{IO.ANSI.red}ERROR: #{inspect reason}")
      %Maxwell.Conn{} = response_conn ->
        stop = System.system_time(:milliseconds)
        diff = stop - start
        log_response_message(options, response_conn, diff)
    end
    new_result
  end

  defp log_response_message(options, conn, diff) do
    %Maxwell.Conn{status: status, url: url, method: method} = conn
    level = get_level(options, status)
    color =
      case level do
        nil    -> nil
        :debug -> IO.ANSI.cyan
        :info  -> IO.ANSI.normal
        :warn  -> IO.ANSI.yellow
        :error -> IO.ANSI.red
      end

    unless is_nil(level) do
      message = "#{method} #{url} <<<#{color}#{status}(#{diff}ms)#{IO.ANSI.reset}\n#{inspect conn}"
      Logger.log(level, message)
    end
  end

  defp get_level([], _code),                      do: nil
  defp get_level([{code, level} | _], code),      do: level
  defp get_level([{from..to, level} | _], code)
  when code in from..to,                          do: level
  defp get_level([{:default, level} | _], _code), do: level
  defp get_level([_ | t], code),                  do: get_level(t, code)


  defp parse_opts(options),             do: parse_opts(options, [], nil)
  defp parse_opts([], result, nil),     do: Enum.reverse(result)
  defp parse_opts([], result, default), do: Enum.reverse([{:default, default} | result])

  defp parse_opts([{level, :default} | rest], result, nil) do
    check_level(level)
    parse_opts(rest, result, level)
  end

  defp parse_opts([{level, :default} | rest], result, level) do
    Logger.warn "Logger Middleware: default level defined multiple times."
    parse_opts(rest, result, level)
  end

  defp parse_opts([{_level, :default} | _rest], _result, _default) do
    raise ArgumentError, "Logger Middleware: default level conflict."
  end

  defp parse_opts([{level, codes} | rest], result, default) when is_list(codes) do
    check_level(level)
    result = Enum.reduce(codes, result, fn code, acc ->
      check_code(code)
      [{code, level} | acc]
    end)
    parse_opts(rest, result, default)
  end

  defp parse_opts([{level, code} | rest], result, default) do
    check_level(level)
    check_code(code)
    parse_opts(rest, [{code, level} | result], default)
  end


  defp check_level(level) when level in @levels,  do: :ok
  defp check_level(_level) do
    raise ArgumentError, "Logger Middleware: level only accepts #{inspect @levels}."
  end


  defp check_code(code) when is_integer(code), do: :ok
  defp check_code(_from.._to),                 do: :ok
  defp check_code(_any) do
    raise ArgumentError, "Logger Middleware: status code only accepts Integer and Range."
  end

end
