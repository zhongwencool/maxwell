defmodule GitHubClient.Maxwell do
  @moduledoc  """
     Github API from [Github](https://developer.github.com/v3/)
    """
  # only create get/1, get!/1 methods
  use Maxwell.Builder, ~w(get)a

  adapter Maxwell.Adapter.Ibrowse

  middleware Maxwell.Middleware.BaseUrl, "https://api.github.com"
  middleware Maxwell.Middleware.Opts, [connect_timeout: 6000]
  middleware Maxwell.Middleware.Headers, %{'Accept' => "application/vnd.github.v3+json",
                                           'User-Agent' => "zhongwencool",
                                           'Authorization' => "token c2903158bea876ff10be1934f66ae1255207b79f"}
  middleware Maxwell.Middleware.EncodeJson
  middleware Maxwell.Middleware.DecodeJson

# auto decode reponse to json
  def home do
    get!
  end

# auto link base url and url path
  def current_user_url do
    [url: "/user"]
    |> get!
  end

# auth encode query string into url
  def code_search_url(name) do
    [url: "/search/code",
     query: %{q: "addClass in:file language:js repo:jquery/jquery"},
     headers: %{'User-Agent' => name}
    ]|> get!
  end

  def emails_url do
    [url: "/user/emails"]
    |> get!
  end

  def starred_url do
    [url: "/user/starred"]
    |> get!
  end

end

defmodule GitHubClient.Other do
  @url "https://api.github.com"
  @headers [{'Accept', "application/vnd.github.v3+json"},
            {'Authorization', "token c2903158bea876ff10be1934f66ae1255207b79f"},
            {'User-Agent', "zhongwencool"}]
  @opts [connect_timeout: 6000]

# Do more operations (compare maxwell) by yourself
# 1. url + query encode by yourself
# 2. @url @headers @opts is settled, you should change it by yourself
# 3. request boby and reponse must encode/decode by yourself

  def home do
    url = to_char_list(@url)
    case :ibrowse.send_req(url, @headers, :get, [], @opts) do
      {:ok, status, headers, body} ->
        {status, _}= status|> to_string |> Integer.parse
        %{status: status,
           headers: headers,
           body: Poison.decode!(body)
         }
      {:error, _reason} = error ->
        raise error
    end
  end

  def code_search_url(name) do
    query = %{q: "addClass in:file language:js repo:jquery/jquery"}
    url =  (to_string(@url) <> "/search/code?" <> URI.encode_query(query)) |> to_char_list
    headers = List.keyreplace(@headers, 'User-Agent', 0, {'User-Agent', name})

    case :ibrowse.send_req(url, headers, :get, [], @opts) do
      {:ok, status, headers, body} ->
        {status, _}= status|> to_string |> Integer.parse
        %{status: status,
          headers: headers,
          body: Poison.decode!(body)
         }
      {:error, _reason} = error ->
        throw error
    end
  end

end
