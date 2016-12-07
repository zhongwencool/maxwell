defmodule Maxwell.Builder.Until do
  @moduledoc  """
  Utils for builder
  """

  @doc """
  Global default adapter.
  ## Examples
  ```ex
    config :maxwell,
    default_adapter: Maxwell.Adapter.Hackney
  ```
  """
  def default_adapter do
    Application.get_env(:maxwell, :default_adapter, Maxwell.Adapter.Ibrowse)
  end

  @doc """
  Serialize http method to atom lists
    * `methods` - http methods list, for example: ~w(get), [:get], ["get"]
    * `default_methods` - all http method lists.
    *  raise ArgumentError when method is not atom list, string list or ~w(get put).
  ## Examples
  ```ex
    [:get, :head, :delete, :trace, :options, :post, :put, :patch]
  ```
  """
  def serialize_method_to_atom([], default_methods), do: default_methods
  def serialize_method_to_atom(methods = [atom|_], _)when is_atom(atom), do: methods
  def serialize_method_to_atom({:sigil_w, _, [{:<<>>, _, [methods_str]}, _]}, _) do
    methods_str |> String.split(" ") |> Enum.map(&String.to_atom/1)
  end
  def serialize_method_to_atom(methods = [str|_], _)when is_binary(str) do
    for method <- methods, do: String.to_atom(method)
  end
  def serialize_method_to_atom(methods, _) do
    raise ArgumentError, "http methods format must be [:get] or [\"get\"] or ~w(get) or ~w(get)a #{methods}"
  end

  @doc """
  Make sure all `list` in `allow_methods`,
  otherwise raise ArgumentError

  ## Examples
  ```
     iex> allow_methods?([:Get], [:post, :head, :get])
     ** (ArgumentError) http methods don't support Get
  ```
  """
  def allow_methods?([], _allow_methods), do: true
  def allow_methods?([method|methods], allow_methods) do
    unless method in allow_methods, do: raise ArgumentError, "http methods don't support #{method}"
    allow_methods?(methods, allow_methods)
  end

end

