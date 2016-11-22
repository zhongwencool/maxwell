defmodule Maxwell.Builder.Adapter do
  @doc """
  ```
  # module
  @adapter Adapter.Module
  # or function
  @adapter fn(env = %Maxwell{}) -> {:ok, env = %Maxwell{}} / {:error, term()} end
  ```
  """
  defmacro adapter({:fn, _, _} = ad) do
    escaped = Macro.escape(ad)
    quote do
      @adapter unquote(escaped)
    end
  end
  defmacro adapter(adapter) do
    quote do
      @adapter unquote(adapter)
    end
  end
end
