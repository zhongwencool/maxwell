defmodule Maxwell.Builder do
  @moduledoc false
  @http_methods [:get, :head, :delete, :trace, :options, :post, :put, :patch]
  @method_without_body [{:get!, :get}, {:head!, :head}, {:delete!, :delete}, {:trace!, :trace}, {:options!, :options}]
  @method_with_body [{:post!, :post}, {:put!, :put}, {:patch!, :patch}]

  defmacro __using__(methods) do
    methods = Maxwell.Builder.Until.adjust_method_format(methods, @http_methods)
    Maxwell.Builder.Until.allow_methods?(methods, @http_methods)

    method_defs = for {method_exception, method} <- @method_without_body, method in methods do
      quote location: :keep do
        @doc """
          Method without body: #{unquote(method)}

          Receives `%Maxwell.Conn{}`

          Returns `{:ok, %Maxwell.Conn{}}` or `{:error, reason_term}`
          ## Examples
               iex> url(request_url_string_or_char_list)
                    |> query(request_query_map)
                    |> headers(request_headers_map)
                    |> opts(request_opts_keyword_list)
                    |> YourClient.#{unquote(method)}

               {:ok, %Maxwell.Conn{
                      headers: reponse_headers_map,
                      status:  reponse_http_status_integer,
                      body:    reponse_body_term,
                      opts:    request_opts_keyword_list,
                      url:     request_urlwithquery_string,
                      query:   request_query_map
               }

          or
                {:error, {:conn_failed, {:error, :nxdomain}}}

          You can make asynchronous requests by passing `respond_to: pid` option:
                Maxwell.get(url: "http://example.org", respond_to: self)
                receive do
                  {:maxwell_response, res} -> res.status # => 200
                end
          """
        def unquote(method)(maxwell\\[])
        def unquote(method)(maxwell = %Maxwell.Conn{body: body})when is_nil(body) do
          %{maxwell| method: unquote(method)}
          |> call_middleware
        end
        def unquote(method)(maxwell)when is_list(maxwell) do
          url        = maxwell|> Keyword.get(:url, "")
          headers    = maxwell|> Keyword.get(:headers, %{})
          query      = maxwell|> Keyword.get(:query, %{})
          opts       = maxwell|> Keyword.get(:opts, [])

          opts =
          if respond_to = maxwell|> Keyword.get(:respond_to, nil) do
            [{:respond_to, respond_to} | opts]
          else
            opts
          end

          %Maxwell.Conn{
            method: unquote(method),
            headers: headers,
            opts: opts,
            url: Maxwell.Conn.append_query_string(url, query)
          }
          |> call_middleware
        end
        @doc """
          Method without body: #{unquote(method_exception)}

          Receives `%Maxwell.Conn{}`

          Returns `%Maxwell.Conn{}` or raise `%MaxWell.Error{}`

          """
        def unquote(method_exception)(maxwell\\%Maxwell.Conn{})
        def unquote(method_exception)(maxwell) do
          case unquote(method)(maxwell) do
            {:ok, %Maxwell.Conn{} = result} ->
              result
            {:error, reason}  ->
              raise Maxwell.Error, value: reason,
                message: "method: #{unquote(method)} reason: #{inspect reason} url: #{maxwell.url}, module: #{__MODULE__}"
          end
        end
      end
    end

    method_defs_with_body = for {method_exception, method} <- @method_with_body, method in methods do
      quote location: :keep do
        @doc """
          Method: #{unquote(method)}

          Receives `%Maxwell.Conn{}`

          Returns `{:ok, %Maxwell.Conn{}}` or `{:error, reason}`
          ## Examples
               iex> url(request_url_string_or_char_list)
                    |> query(request_query_map)
                    |> headers(request_headers_map)
                    |> opts(request_opts_keyword_list)
                    |> body(request_body_term)
                    |> YourClient.#{unquote(method)}

               {:ok, %Maxwell.Conn{
                     headers: reponse_headers_map,
                     status:  reponse_http_status_integer,
                     body:    reponse_body_term,
                     opts:    request_opts_keyword_list
                     url:     request_urlwithquery_string,
               }
          or
               {:error, {:conn_failed, {:error, :timeout}}}
          If adapter supports it, you can make asynchronous requests by passing `respond_to: pid` option:
                Maxwell.get(url: "http://example.org", respond_to: self)
                receive do
                  {:maxwell_response, res} -> res.status # => 200
                end
          """
        def unquote(method)(maxwell\\%Maxwell.Conn{})
        def unquote(method)(maxwell = %Maxwell.Conn{}) do
          %{maxwell| method: unquote(method)}
          |> call_middleware
        end
        def unquote(method)(maxwell)when is_list(maxwell) do
          url        = maxwell |> Keyword.get(:url, "")
          headers    = maxwell |> Keyword.get(:headers, %{})
          query      = maxwell |> Keyword.get(:query, %{})
          opts       = maxwell |> Keyword.get(:opts, [])
          body       = maxwell |> Keyword.get(:body, %{})

          opts =
          if respond_to = maxwell|> Keyword.get(:respond_to, nil) do
            [{:respond_to, respond_to} | opts]
          else
            opts
          end

          body =
          if multipart = maxwell|> Keyword.get(:multipart, nil) do
            {:multipart, multipart}
          else
            body
          end

          %Maxwell.Conn{
            method: unquote(method),
            headers: headers,
            opts: opts,
            body: body,
            url: Maxwell.Conn.append_query_string(url, query)
          }
          |> call_middleware
        end
        @doc """
          Method: #{unquote(method_exception)}

          Receives `%Maxwell.Conn{}`

          Return `%Maxwell.Conn{}` or raise `%Maxwell.Error{}`

          """
        def unquote(method_exception)(maxwell\\%Maxwell.Conn{})
        def unquote(method_exception)(maxwell) do
          case unquote(method)(maxwell) do
            {:ok, %Maxwell.Conn{} = result} ->
              result
            {:error, reason}  ->
              raise Maxwell.Error, value: reason,
                message: "method: #{unquote(method)} reason: #{inspect reason} url: #{maxwell.url}, module: #{__MODULE__}"
          end
        end
      end
    end

    quote do
      unquote(method_defs)
      unquote(method_defs_with_body)

      import Maxwell.Builder.Middleware
      import Maxwell.Builder.Adapter
      import Maxwell.Conn

      Module.register_attribute(__MODULE__, :middleware, accumulate: true)
      @before_compile Maxwell.Builder
    end
  end

  defp generate_call_adapter(module) do
    adapter = Module.get_attribute(module, :adapter)
    env = quote do: env
    adapter_call = quote_adapter_call(adapter, env)
    quote do
      defp call_adapter(unquote(env)) do
        unquote(adapter_call)
      end
    end
  end

  defp generate_call_middleware(module) do
    env = quote do: env
    call_adapter = quote do: call_adapter(unquote(env))
    middleware = Module.get_attribute(module, :middleware)
    middleware_call = middleware |> Enum.reduce(call_adapter, &quote_middleware_call(env, &1, &2))
    quote do
      defp call_middleware(unquote(env)) do
        unquote(middleware_call)
      end
    end
  end

  defp quote_middleware_call(env, {mid, args}, acc) do
    quote do
      unquote(mid).call(unquote(env), fn(unquote(env)) -> unquote(acc) end, unquote(Macro.escape(args)))
    end
  end

  defp quote_adapter_call(nil, env) do
    quote do
      unquote(Maxwell.Builder.Until.default_adapter).call(unquote(env))
    end
  end

  defp quote_adapter_call({:fn, _, _} = adapter, env) do
    quote do
      unquote(adapter).(unquote(env))
    end
  end

  defp quote_adapter_call(mod, env) when is_atom(mod) do
    case Atom.to_char_list(mod) do
      ~c"Elixir." ++ _ ->
        # delegate to an elixir module
        quote do
          unquote(mod).call(unquote(env))
        end
      _ ->
        # delegate to a local call
        quote do
          unquote(mod)(unquote(env))
        end
    end
  end

  defp quote_adapter_call(_, _) do
    raise "Adapter must be Module, fn(env) -> env or atom end"
  end

  defmacro __before_compile__(env) do
    [
      generate_call_adapter(env.module),
      generate_call_middleware(env.module),
    ]
  end

end

