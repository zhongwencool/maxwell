defmodule BuilderExceptionTest do
  use ExUnit.Case

  test "Builder Method Exception Test" do
    assert_raise ArgumentError, "http methods don't support gett", fn ->
      defmodule TAtom do
        use Maxwell.Builder, ~w(gett)
      end
    end
  end

  test "Builder Method Format integer " do
    assert_raise ArgumentError, "http methods format must be [:get] or [\"get\"] or ~w(get) or ~w(get)a 12345", fn ->
      defmodule TInteger do
        use Maxwell.Builder, 12345
      end
    end
  end

  test "Builder Adapter Exception Test" do
    assert_raise ArgumentError, "Adapter must be Module", fn ->
      defmodule TAdapter do
        use Maxwell.Builder, ~w(get)
        adapter 1
      end
    end
  end

  test "method with binary methods" do
    assert_raise RuntimeError, "ok", fn ->
      defmodule TBinary do
        use Maxwell.Builder, ["get", "post"]
      end
      raise "ok"
    end
  end

  test "method with atom methods" do
    assert_raise RuntimeError, "ok", fn ->
      defmodule TAtomList do
        use Maxwell.Builder, [:get, :post]
      end
      raise "ok"
    end
  end
end

