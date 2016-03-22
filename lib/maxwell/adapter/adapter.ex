defmodule Maxwell.Adapter do
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

  def default_adapter do
    Application.get_env(:maxwell, :default_adapter, Maxwell.Adapter.Ibrowse)
  end

end
