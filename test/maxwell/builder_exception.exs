defmodule BuilderExceptionTest do
  use ExUnit.Case

  test "BuilderExceptionTest" do
    assert_raise RuntimeError, "http methods don't support gett", fn ->
      defmodule T do
        use Maxwell.Builder, ~w(gett)
      end
    end
  end

end
