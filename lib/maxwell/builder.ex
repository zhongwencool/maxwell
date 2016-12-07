defmodule Maxwell.Builder do
  @moduledoc """
  Conveniences for building maxwell.

  This module can be `use`-d into a module in order to build.

  `Maxwell.Builder` also imports the `Maxwell.Conn` module, making functions like
  `get_*`/`put_*` available.

  ## Options
  When used, the following options are accepted by `Maxwell.Builder`:
    * `~w(get)a` - only create `get/1` and `get!/1` functions,
    default is `~w(get head delete trace options post put patch)a`

  ## Examples

  ```ex
     use Maxwell.Builder
     use Maxwell.Builder, ~w(get put)a
     use Maxwell.Builder, ["get", "put"]
     use Maxwell.Builder, [:get, :put]
  ```

  """
  @http_methods [:get, :head, :delete, :trace, :options, :post, :put, :patch]
  @method_without_body [{:get!, :get}, {:head!, :head}, {:delete!, :delete}, {:trace!, :trace}, {:options!, :options}]
  @method_with_body [{:post!, :post}, {:put!, :put}, {:patch!, :patch}]

  defmacro __using__(methods) do
    methods = Maxwell.Builder.Until.serialize_method_to_atom(methods, @http_methods)
    Maxwell.Builder.Until.allow_methods?(methods, @http_methods)

    method_defs = for {method_exception, method} <- @method_without_body, method in methods do
      quote location: :keep do
        @doc """
        Method #{unquote(method)} without request body.

          * `conn` - `%Maxwell.Conn{}`

        Returns `{:ok, %Maxwell.Conn{}}` or `{:error, reason_term, %Maxwell.Conn{}}`.

        ## Examples
        """
        def unquote(method)(conn \\ %Maxwell.Conn{})
        def unquote(method)(conn = %Maxwell.Conn{req_body: nil}) do
          %{conn| method: unquote(method)} |> call_middleware
        end
        def unquote(method)(conn) do
          raise Maxwell.Error, {__MODULE__, "#{unquote(method)}/1 should not contain body", conn};
        end

        @doc """
        Method #{unquote(method_exception)} without request body.

          * `conn` - see `#{unquote(method)}/1`

        Returns `%Maxwell.Conn{}` or raise `%MaxWell.Error{}` when status not in [200..299].

        ## Examples
        """
        def unquote(method_exception)(conn \\ %Maxwell.Conn{})
        def unquote(method_exception)(conn) do
          case unquote(method)(conn) do
            {:ok, %Maxwell.Conn{status: status} = new_conn} when status in 200..299 -> new_conn;
            {:ok, new_conn} -> raise Maxwell.Error, {__MODULE__, :response_status_not_match, new_conn};
            {:error, reason, new_conn} -> raise Maxwell.Error, {__MODULE__, reason, new_conn}
          end
        end
        @doc """
        Method #{unquote(method_exception)} without request body.

        * `conn` - see `#{unquote(method)}/1`
        * `normal_statuses` - the specified status which not raise exception, for example: [200, 201]

        Returns `%Maxwell.Conn{}` or raise `%MaxWell.Error{}`.

        ## Examples
        """
        def unquote(method_exception)(conn, normal_statuses)when is_list(normal_statuses) do
          case unquote(method)(conn) do
            {:ok, %Maxwell.Conn{status: status} = new_conn} ->
              unless status in normal_statuses do
                raise Maxwell.Error, {__MODULE__, :response_status_not_match, conn}
              end
              new_conn;
            {:error, reason, new_conn}  ->
              raise Maxwell.Error, {__MODULE__, reason, new_conn}
          end
        end
      end
    end

    method_defs_with_body = for {method_exception, method} <- @method_with_body, method in methods do
      quote location: :keep do
        @doc """
          Method: #{unquote(method)}.

          * `conn` - `%Maxwell.Conn{}`.

          Returns `{:ok, %Maxwell.Conn{}}` or `{:error, reason, %Maxwell.Conn{}}`
          ## Examples
          """
        def unquote(method)(conn \\ %Maxwell.Conn{})
        def unquote(method)(conn = %Maxwell.Conn{}) do
          %{conn| method: unquote(method)} |> call_middleware
        end
        @doc """
          Method: #{unquote(method_exception)}

          * `conn` - see `#{unquote(method)}/1`

          Return `%Maxwell.Conn{}` or raise `%Maxwell.Error{}` when status not in [200.299]
          ## Examples
          """
        def unquote(method_exception)(conn \\ %Maxwell.Conn{})
        def unquote(method_exception)(conn) do
          case unquote(method)(conn) do
            {:ok, %Maxwell.Conn{status: status} = new_conn} when status in 200..299 -> new_conn;
            {:ok, new_conn} -> raise Maxwell.Error, {__MODULE__, :response_status_not_match, new_conn}
            {:error, reason, new_conn}  -> raise Maxwell.Error, {__MODULE__, reason, new_conn}
          end
        end
        @doc """
        Method #{unquote(method_exception)} with request body.

        * `conn` - see `#{unquote(method)}/1`
        * `normal_statuses` - the specified status which not raise exception, for example: [200, 201]

        Returns `%Maxwell.Conn{}` or raise `%MaxWell.Error{}`.

        ## Examples
        """
        def unquote(method_exception)(conn, normal_statuses) when is_list(normal_statuses) do
          case unquote(method)(conn) do
            {:ok, %Maxwell.Conn{status: status} = new_conn} ->
              unless status in normal_statuses do
                raise Maxwell.Error, {__MODULE__, :response_status_not_match, new_conn}
              end
              new_conn;
            {:error, reason, new_conn}  ->
              raise Maxwell.Error, {__MODULE__, reason, new_conn}
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
  defp quote_adapter_call(mod, env) when is_atom(mod) do
    quote do
      unquote(mod).call(unquote(env))
    end
  end

  defp quote_adapter_call(_, _) do
    raise ArgumentError, "Adapter must be Module, fn(env) -> env end or atom"
  end

  defmacro __before_compile__(env) do
    [
      generate_call_adapter(env.module),
      generate_call_middleware(env.module),
    ]
  end

end

