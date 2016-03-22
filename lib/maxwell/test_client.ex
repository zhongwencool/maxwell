defmodule Maxwell.TestClient do

  # use Maxwell.Builder, ~w(get post patch)a #[:get, :post, :patch]
  # use Maxwell.Builder, ["get", "post"]
  use Maxwell.Builder, ~w(get post)a
  middleware Maxwell.Middleware.BaseUrl, "https://api.github.com"
  middleware Maxwell.Middleware.Opts, [connect_timeout: 3000]
  middleware Maxwell.Middleware.Headers, %{'Content-Type': "application/vnd.github.v3+json", 'User-Agent': 'zhongwenool'}
  middleware Maxwell.Middleware.DecodeJson

end

