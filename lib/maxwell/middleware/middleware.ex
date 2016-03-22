defmodule Maxwell.Middleware do
  defmacro middleware(middleware, opts\\[]) do
    quote do
      @middleware {unquote(middleware), unquote(opts)}
    end
  end
end
