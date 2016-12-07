defmodule Maxwell.Adapter do
  @moduledoc  """
  Define adapter behaviour
  ## Examples
  See `Maxwell.Adapter.Ibrowse`
  """
  @type return_t :: {:ok, Maxwell.Conn.t} | {:error, any, Maxwell.Conn.t}
  @callback call(Maxwell.Conn.t) :: return_t

end

