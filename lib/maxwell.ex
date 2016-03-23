defmodule Maxwell do
  @moduledoc  """
  #{File.read!("README.md")}
  """

  defstruct url: "",
            method: nil,
            headers: %{},
            body: nil,
            opts: [],
            status: nil
            
  use Maxwell.Builder

end
