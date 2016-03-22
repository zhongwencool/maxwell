defmodule Maxwell do
  @moduledoc  """
  #{File.read!("README.md")}
  """

  defstruct url: "",
            method: nil,
            headers: %{},
            body: nil,
            opts: [],
            status: nil,
            _module_: nil
            
  use Maxwell.Builder

end
