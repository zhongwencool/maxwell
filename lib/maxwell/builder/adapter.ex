defmodule Maxwell.Builder.Adapter do
  @moduledoc """
  Adapter macro.
  ## Example
  ```
  # module
  @adapter Adapter.Module
  ```
  """
  defmacro adapter(adapter) do
    quote do
      @adapter unquote(adapter)
    end
  end
end
