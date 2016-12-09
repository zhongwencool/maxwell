defmodule ConnTest do
  use ExUnit.Case

  import Maxwell.Conn
  alias Maxwell.Conn
  alias Maxwell.Conn.AlreadySentError
  alias Maxwell.Conn.NotSentError

  test "new/0 new/1 test" do
    assert new() == %Conn{}
    assert new("http://example.com") == %Conn{url: "http://example.com"}
  end

  test "put_path/2 test" do
    assert put_path(%Conn{state: :unsent}, "/login") == %Conn{state: :unsent, path: "/login"}
    assert_raise AlreadySentError, "the request was already sent", fn ->
      put_path(%Conn{state: :sent}, "/login")
    end
  end

  test "put_query_string/2 put_query_string/3 test" do
    assert put_query_string(%Conn{}, "name", "foo") == %Conn{state: :unsent, query_string: %{"name" => "foo"}}
    assert put_query_string(%Conn{state: :unsent}, "name", "foo") == %Conn{state: :unsent, query_string: %{"name" => "foo"}}
    assert put_query_string(%{"name" => "foo", "passwd" => "123"})
    == %Conn{state: :unsent, query_string: %{"name" => "foo", "passwd" => "123"}}

    assert_raise AlreadySentError, "the request was already sent", fn ->
      put_query_string(%Conn{state: :sent}, %{"name" => "foo"})
    end
    assert_raise AlreadySentError, "the request was already sent", fn ->
      put_query_string(%Conn{state: :sent}, "name", "foo")
    end
  end

  test "put_req_header/2 put_req_header/3 test" do
    assert put_req_header(%Conn{}, "cache-control", "no-cache")
    assert put_req_header(%Conn{state: :unsent}, "cache-control", "no-cache")
    == %Conn{state: :unsent, req_headers: %{"cache-control" => "no-cache"}}
    assert put_req_header(%{"cache-control" => "no-cache", "ETag" => "rFjdsDtv2qxk7K1CwG4VMlF836E="})
    == %Conn{state: :unsent, req_headers: %{"cache-control" => "no-cache", "ETag" => "rFjdsDtv2qxk7K1CwG4VMlF836E="}}

    assert_raise AlreadySentError, "the request was already sent", fn ->
      put_req_header(%Conn{state: :sent}, %{"cache-control" => "no-cache"})
    end
    assert_raise AlreadySentError, "the request was already sent", fn ->
      put_req_header(%Conn{state: :sent}, "cache-control", "no-cache")
    end
  end

  test "put_option/2 put_option/3 test" do
    conn0 = put_option(%Conn{state: :unsent, opts: [max_attempts: 3]}, :connect_timeout, 3000)
    assert Keyword.equal?(conn0.opts, [connect_timeout: 3000, max_attempts: 3])
    conn1 = put_option(%Conn{state: :unsent, opts: [max_attempts: 3]}, :connect_timeout, 3000)
    assert Keyword.equal?(conn1.opts, [connect_timeout: 3000, max_attempts: 3])
    conn2 = put_option(%Conn{state: :unsent, opts: [max_attempts: 3]}, [connect_timeout: 3000])
    assert Keyword.equal?(conn2.opts, [connect_timeout: 3000, max_attempts: 3])
    assert_raise AlreadySentError, "the request was already sent", fn ->
      put_option(%Conn{state: :sent}, :connect_timeout, 3000)
    end
  end

  test "put_req_body/2 test"  do
    assert put_req_body(%Conn{state: :unsent, req_body: "old"}, "new") == %Conn{state: :unsent, req_body: "new"}
    assert_raise AlreadySentError, "the request was already sent", fn ->
      put_req_body(%Conn{state: :sent}, "new")
    end
  end

  test "get_status/1 test" do
    assert get_status(%Conn{state: :sent, status: 200}) == 200
    assert_raise NotSentError, "the request was not sent yet", fn ->
      get_status(%Conn{state: :unsent})
    end
  end

  test "get_resp_header/2 get_resp_header/3 test" do
    assert get_resp_header(%Conn{state: :sent, resp_headers: %{"Server" => "Microsoft-IIS/8.5"}})
    == %{"Server" => "Microsoft-IIS/8.5"}
    assert get_resp_header(%Conn{state: :sent, resp_headers: %{"Server" => "Microsoft-IIS/8.5"}}, "Server")
    == "Microsoft-IIS/8.5"
    assert_raise NotSentError, "the request was not sent yet", fn ->
      get_resp_header(%Conn{state: :unsent}, "Server")
    end
  end

  test "get_resp_body/2 get_resp_body/3 test" do
    assert get_resp_body(%Conn{state: :sent, resp_body: "I'm ok"}) ==  "I'm ok"
    assert get_resp_body(%Conn{state: :sent, resp_body: %{"foo" => %{"addr" => "China"}}}, ["foo", "addr"]) == "China"
    func = fn(body) -> String.split(body, ~r{,}) end
    assert get_resp_body(%Conn{state: :sent, resp_body: "1,2,3"}, func) == ["1", "2", "3"]
    assert_raise NotSentError, "the request was not sent yet", fn ->
      get_resp_body(%Conn{state: :unsent})
    end
  end

  test "append_query_string/2 test" do
    assert "http://example.com/home?name=zhong+wen" == append_query_string("http://example.com", "/home", %{"name" => "zhong wen"})
    assert "http://example.com/home" == append_query_string("http://example.com", "/home", %{})
  end

end

