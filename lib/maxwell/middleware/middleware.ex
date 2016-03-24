defmodule Maxwell.Middleware do
@moduledoc  """
  Example see `Maxwell.Middleware.BaseUrl`
  """

  @doc """
   ```
    @middleware Middleware.Module, opts\\[]
   ```
  """
  defmacro middleware(middleware, opts\\[]) do
    quote do
      @middleware {unquote(middleware), unquote(opts)}
    end
  end
end
