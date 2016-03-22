defmodule Maxwell.Builder do
    @http_methods [:get, :head, :delete, :trace, :options, :post, :put, :patch]
    @method_without_body [{:get!, :get}, {:head!, :head}, {:delete!, :delete}, {:trace!, :trace}, {:options!, :options}]
    @method_with_body [{:post!, :post}, {:put!, :put}, {:patch!, :patch}]

  defmacro __using__(methods) do
    methods = Maxwell.Until.adjust_method_format(methods, @http_methods)
    Maxwell.Until.is_allow_methods(methods, @http_methods)

    method_defs = for {method_exception, method} <- @method_without_body, method in methods do
      quote location: :keep do
        @doc """
          Method without body: #{unquote(method)}

          Receives `[url: url_string, headers: headers_map, query: query_map, opts: opts_keyword_list]`
          
          Returns `{:ok, %Maxwell{}}` or `{:error, reason_term}`
          ## Examples
               iex> [
                      url:     request_url_string_or_char_list,
                      headers: request_headers_map,
                      query:   request_query_map,
                      opts:    request_opts_keyword_list
                    ] |> Maxwell.TestClient.Test.#{unquote(method)}

               {:ok, %Maxwell{
                      headers: reponse_headers_map,
                      status:  reponse_http_status_integer,
                      body:    reponse_body_term,
                      opts:    request_opts_keyword_list,
                      url:     request_urlwithquery_string,
                      query:   request_query_map
               }

          or
                {:error, {:conn_failed, {:error, :nxdomain}}}

          If adapter supports it, you can make asynchronous requests by passing `respond_to: pid` option:
                Maxwell.get(url: "http://example.org", respond_to: self)
                receive do
                  {:maxwell_response, res} -> res.status # => 200
                end
          """
        def unquote(method)(maxwell\\[])
        def unquote(method)(maxwell)when is_list(maxwell) do
          url        = maxwell|> Keyword.get(:url, "")
          headers    = maxwell|> Keyword.get(:headers, %{})
          query      = maxwell|> Keyword.get(:query, %{})
          opts       = maxwell|> Keyword.get(:opts, [])

          if respond_to = maxwell|> Keyword.get(:respond_to, nil) do
            opts = [{:respond_to, respond_to} | opts]
          end

          %Maxwell{
            method: unquote(method),
            _module_: __MODULE__,
            headers: headers,
            opts: opts,
            url: Maxwell.Until.append_query_string(url, query)
          }
          |> request
        end
        @doc """
          Method without body: #{unquote(method_exception)}

          Receives `[url: url_string, headers: headers_map, query: query_map, opts: opts_keyword_list]`

          Returns `%Maxwell{}` or raise `%MaxWell.Error{}`

          """
        def unquote(method_exception)(maxwell\\[])
        def unquote(method_exception)(maxwell) when is_list(maxwell) do
          case unquote(method)(maxwell) do
            {:ok, %Maxwell{} = result} ->
              result
            {:error, reason}  ->
              raise Maxwell.Error, value: reason,
                message: "method: #{unquote(method)} url: #{maxwell.url}, module: #{__MODULE__}"
          end
        end
      end
    end

    method_defs_with_body = for {method_exception, method} <- @method_with_body, method in methods do
      quote location: :keep do
        @doc """
          Method: #{unquote(method)}

          Receives `[url: url_string, headers: headers_map, query: query_map, opts: opts_keyword_list, body: body_term]`

          Returns `{:ok, %Maxwell{}}` or `{:error, reason}`
          ## Examples
               iex> [
                      url:     request_url_string,
                      headers: request_headers_map,
                      query:   request_query_map,
                      body:    request_body_term,
                      opts:    request_opts_keyword_list
                    ] |> Maxwell.YourClient.#{unquote(method)}

               {:ok, %Maxwell{
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
        def unquote(method)(maxwell\\[])
        def unquote(method)(maxwell)when is_list(maxwell) do
          url        = maxwell |> Keyword.get(:url, "")
          headers    = maxwell |> Keyword.get(:headers, %{})
          query      = maxwell |> Keyword.get(:query, %{})
          opts       = maxwell |> Keyword.get(:opts, [])
          body       = maxwell |> Keyword.get(:body, %{})
          if respond_to = maxwell|> Keyword.get(:respond_to, nil) do
            opts = [{:respond_to, respond_to} | opts]
          end

          %Maxwell{
            method: unquote(method),
            _module_: __MODULE__,
            headers: headers,
            opts: opts,
            body: body,
            url: Maxwell.Until.append_query_string(url, query)
          }
          |> request
        end
        @doc """
          Method: #{unquote(method_exception)}

          Receives `[url: url_string, headers: headers_map, query: query_map, opts: opts_keyword_list, body: body_term]`

          Return `%Maxwell{}` or raise `%Maxwell.Error{}`

          """
        def unquote(method_exception)(maxwell\\[])
        def unquote(method_exception)(maxwell)when is_list(maxwell) do
          case unquote(method)(maxwell) do
            {:ok, %Maxwell{} = result} ->
              result
            {:error, reason}  ->
              raise Maxwell.Error, value: reason,
                message: "method: #{unquote(method)} url: #{maxwell.url}, module: #{__MODULE__}"
          end
        end
      end
    end

    request =
      quote location: :keep do
        def request(maxwell = %Maxwell{}) do
          maxwell |> maxwell._module_.call_middleware
        end
      end

    quote do
      unquote(request)
      unquote(method_defs)
      unquote(method_defs_with_body)

      import Maxwell.Middleware
      import Maxwell.Adapter

      Module.register_attribute(__MODULE__, :middleware, accumulate: true)
      @before_compile Maxwell.Builder
    end
  end

  defp generate_call_adapter(env) do
    case Module.get_attribute(env.module, :adapter) do
      nil ->
        quote do
          def call_adapter(env) do
            Maxwell.Adapter.default_adapter.call(env)
          end
        end
      {:fn, _, _} = adapter ->
        quote do
          def call_adapter(env) do
            unquote(adapter).(env)
          end
        end
      mod when is_atom(mod) ->
        quote do
          def call_adapter(env) do
            unquote(mod).call(env)
          end
        end
       _ ->
         raise "Adapter must be Module or fn(env) -> env end"
    end
  end

  defp generate_call_middleware(env) do
    reduced =
      Module.get_attribute(env.module, :middleware)
      |> Enum.reduce(
         quote do
           call_adapter(env)
         end,
         fn({mid, args}, acc) ->
           args = Macro.escape(args)
           quote do
             unquote(mid).call(env, fn(env) -> unquote(acc) end, unquote(args))
           end
         end)

    quote do
      def call_middleware(env) do
        unquote(reduced)
      end
    end
  end

  defmacro __before_compile__(env) do
    [
      generate_call_adapter(env),
      generate_call_middleware(env),
    ]
  end

end
