defmodule Maxwell.Middleware.Logger do
  @moduledoc  """
  Log the request
  Log the response
  ```ex
  # Client.ex
  use Maxwell.Builder ~(get)a
  @middleware Maxwell.Middleware.Log

  def request do
  "/test" |> url |> get!
  end
  ```
  """
  use Maxwell.Middleware
  require Logger

  def request(env, _opts) do
    Logger.info("REQUEST: " <> (format_message(env)))
    env
  end
  def response(result, _opts) do
    case result do
      {:error, reason} ->
        format_reason = :io_lib.format("~p", [reason]) |> to_string
        Logger.error("RESPONSE ERROR: " <> format_reason)
      {:ok, env} ->
        message = "RESPONSE: " <> format_message(env)
        cond do
          env.status >= 400 -> Logger.error message
          env.status >= 300 -> Logger.warn message
          true              -> Logger.info message
        end
    end
    result
  end

  defp format_message(env) do
    method = env.method |> to_string |> String.upcase
    status = case env.status do
               nil -> "";
               200 -> "#{IO.ANSI.green} => 200"
               status1 -> " => #{status1}"
             end
    header = case Map.equal?(env.headers, %{}) do
               true -> ""
               false -> :io_lib.format("~p", [env.headers]) |> to_string
             end
    options = case env.opts do
                [] -> ""
                options -> :io_lib.format("~p", [options]) |> to_string
              end
    "#{method} #{env.url} #{header} #{options} #{status}"
  end

end

