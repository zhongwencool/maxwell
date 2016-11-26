defmodule Maxwell.Builder.Until do
  @moduledoc  """
  Utils for build
  """

  @doc """
  Global default adapter.
  ```ex
    config :maxwell,
    default_adapter: Maxwell.Adapter.Hackney
  ```
  """
  def default_adapter do
    Application.get_env(:maxwell, :default_adapter, Maxwell.Adapter.Ibrowse)
  end

  @doc """
  Generate Http method functions
  ```ex
    [:get, :head, :delete, :trace, :options, :post, :put, :patch]
  ```
  """
  def adjust_method_format(methods, default_methods) do
    case methods do
      [] ->
        default_methods
      {:sigil_w, _, [{:<<>>, _, [methods_str]}, _]} ->
        methods_str |> String.split(" ") |> Enum.map(&String.to_atom/1)
      [method| _] when is_atom(method) ->
        methods
      [method|_] when is_binary(method) ->
        methods |> Enum.map(&String.to_atom/1)
      _ ->
        raise "http methods format must be [:get] or [\"get\"] or ~w(get) or ~w(get)a #{methods}"
    end
  end

  @doc """
    Check method is allowed
  """
  def allow_methods?(methods, allow_methods) do
    Enum.each(methods,
      fn(method) ->
        unless method in allow_methods do
          raise "http methods don't support #{method}"
        end
      end)
  end

end
