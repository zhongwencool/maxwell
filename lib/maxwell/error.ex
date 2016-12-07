defmodule Maxwell.Error do
  @moduledoc  """
  Exception `%Maxwell.Error{:url, :reason, :message, :status, :conn}`
  ## Example
  ```
  raise Maxwell.Error, {__MODULE__, reason, conn};
  ```
  """
  defexception [:url, :status, :method, :reason, :message, :conn]

  def exception({module, reason, conn}) do
    %Maxwell.Conn{url: url, status: status, method: method} = conn
    message = """
    url: #{url}
    method: #{method}
    reason: #{inspect reason}
    module: #{module}
    """
    %Maxwell.Error{url: url, status: status, method: method, message: message, conn: conn}
  end

end
