defmodule ConnTest do
  use ExUnit.Case

  import Maxwell.Conn
  import ExUnit.CaptureIO
  alias Maxwell.Conn
  alias Maxwell.Conn.AlreadySentError
  alias Maxwell.Conn.NotSentError

  test "new/0" do
    assert new() == %Conn{}
  end

  test "new/1" do
    assert new("localhost") == %Conn{url: "http://localhost"}
    assert new("localhost:8080") == %Conn{url: "http://localhost:8080"}
    assert new("example") == %Conn{path: "/example"}
    assert new("example.com") == %Conn{url: "http://example.com"}
    assert new("example.com:8080") == %Conn{url: "http://example.com:8080"}
    assert new("http://example.com") == %Conn{url: "http://example.com"}
    assert new("https://example.com") == %Conn{url: "https://example.com"}
    assert new("https://example.com:8080") == %Conn{url: "https://example.com:8080"}
    assert new("http://example.com/foo") == %Conn{url: "http://example.com", path: "/foo"}

    assert new("http://example.com:8080/foo") == %Conn{
             url: "http://example.com:8080",
             path: "/foo"
           }

    assert new("http://user:pass@example.com:8080/foo") == %Conn{
             url: "http://user:pass@example.com:8080",
             path: "/foo"
           }

    assert new("http://example.com/foo?version=1") == %Conn{
             url: "http://example.com",
             path: "/foo",
             query_string: %{"version" => "1"}
           }

    assert new("http://example.com/foo?ids[]=1&ids[]=2") == %Conn{
             url: "http://example.com",
             path: "/foo",
             query_string: %{"ids" => ["1", "2"]}
           }

    assert new("http://example.com/foo?ids[foo]=1") == %Conn{
             url: "http://example.com",
             path: "/foo",
             query_string: %{"ids" => %{"foo" => "1"}}
           }
  end

  test "deprecated: put_path/1" do
    assert capture_io(:stderr, fn ->
             assert put_path("/login") == %Conn{state: :unsent, path: "/login"}
           end) =~ "deprecated"
  end

  test "put_path/2 test" do
    assert put_path(%Conn{state: :unsent}, "/login") == %Conn{state: :unsent, path: "/login"}

    assert_raise AlreadySentError, "the request was already sent", fn ->
      put_path(%Conn{state: :sent}, "/login")
    end
  end

  test "deprecated: put_query_string/1" do
    assert capture_io(:stderr, fn ->
             assert put_query_string(%{"name" => "foo", "passwd" => "123"}) ==
                      %Conn{state: :unsent, query_string: %{"name" => "foo", "passwd" => "123"}}
           end) =~ "deprecated"
  end

  test "put_query_string/2" do
    assert put_query_string(new(), %{"name" => "foo", "passwd" => "123"}) ==
             %Conn{state: :unsent, query_string: %{"name" => "foo", "passwd" => "123"}}

    assert_raise AlreadySentError, "the request was already sent", fn ->
      put_query_string(%Conn{state: :sent}, %{"name" => "foo"})
    end
  end

  test "put_query_string/3" do
    assert put_query_string(%Conn{}, "name", "foo") == %Conn{
             state: :unsent,
             query_string: %{"name" => "foo"}
           }

    assert put_query_string(%Conn{state: :unsent}, "name", "foo") == %Conn{
             state: :unsent,
             query_string: %{"name" => "foo"}
           }

    assert_raise AlreadySentError, "the request was already sent", fn ->
      put_query_string(%Conn{state: :sent}, "name", "foo")
    end
  end

  test "put_req_headers/2" do
    assert put_req_headers(new(), %{
             "cache-control" => "no-cache",
             "ETag" => "rFjdsDtv2qxk7K1CwG4VMlF836E="
           }) ==
             %Conn{
               state: :unsent,
               req_headers: %{
                 "cache-control" => "no-cache",
                 "etag" => "rFjdsDtv2qxk7K1CwG4VMlF836E="
               }
             }

    assert put_req_headers(new(), %{
             "cache-control" => "no-cache",
             "ETag" => "rFjdsDtv2qxk7K1CwG4VMlF836E="
           }) ==
             %Conn{
               state: :unsent,
               req_headers: %{
                 "cache-control" => "no-cache",
                 "etag" => "rFjdsDtv2qxk7K1CwG4VMlF836E="
               }
             }

    assert_raise AlreadySentError, "the request was already sent", fn ->
      put_req_headers(%Conn{state: :sent}, %{"cache-control" => "no-cache"})
    end
  end

  test "deprecated: put_req_header/1" do
    assert capture_io(:stderr, fn ->
             assert put_req_header(%{
                      "cache-control" => "no-cache",
                      "ETag" => "rFjdsDtv2qxk7K1CwG4VMlF836E="
                    }) ==
                      %Conn{
                        state: :unsent,
                        req_headers: %{
                          "cache-control" => "no-cache",
                          "etag" => "rFjdsDtv2qxk7K1CwG4VMlF836E="
                        }
                      }
           end) =~ "deprecated"
  end

  test "deprecated: put_req_header/2" do
    assert capture_io(:stderr, fn ->
             assert put_req_header(new(), %{
                      "cache-control" => "no-cache",
                      "ETag" => "rFjdsDtv2qxk7K1CwG4VMlF836E="
                    }) ==
                      %Conn{
                        state: :unsent,
                        req_headers: %{
                          "cache-control" => "no-cache",
                          "etag" => "rFjdsDtv2qxk7K1CwG4VMlF836E="
                        }
                      }

             assert put_req_header(new(), %{
                      "cache-control" => "no-cache",
                      "ETag" => "rFjdsDtv2qxk7K1CwG4VMlF836E="
                    }) ==
                      %Conn{
                        state: :unsent,
                        req_headers: %{
                          "cache-control" => "no-cache",
                          "etag" => "rFjdsDtv2qxk7K1CwG4VMlF836E="
                        }
                      }

             assert_raise AlreadySentError, "the request was already sent", fn ->
               put_req_header(%Conn{state: :sent}, %{"cache-control" => "no-cache"})
             end
           end) =~ "deprecated"
  end

  test "put_req_header/3" do
    assert put_req_header(new(), "cache-control", "no-cache")

    assert put_req_header(new(), "cache-control", "no-cache") ==
             %Conn{state: :unsent, req_headers: %{"cache-control" => "no-cache"}}

    assert_raise AlreadySentError, "the request was already sent", fn ->
      put_req_header(%Conn{state: :sent}, "cache-control", "no-cache")
    end
  end

  test "put_options/2" do
    conn = put_options(%Conn{state: :unsent, opts: [max_attempts: 3]}, connect_timeout: 3000)
    assert Keyword.equal?(conn.opts, connect_timeout: 3000, max_attempts: 3)

    assert_raise AlreadySentError, "the request was already sent", fn ->
      put_options(%Conn{state: :sent}, connect_timeout: 3000)
    end
  end

  test "deprecated: put_option/1" do
    assert capture_io(:stderr, fn ->
             conn = put_option(connect_timeout: 3000)
             assert Keyword.equal?(conn.opts, connect_timeout: 3000)
           end) =~ "deprecated"
  end

  test "deprecated: put_option/2" do
    assert capture_io(:stderr, fn ->
             conn =
               put_option(%Conn{state: :unsent, opts: [max_attempts: 3]}, connect_timeout: 3000)

             assert Keyword.equal?(conn.opts, connect_timeout: 3000, max_attempts: 3)

             assert_raise AlreadySentError, "the request was already sent", fn ->
               put_option(%Conn{state: :sent}, connect_timeout: 3000)
             end
           end) =~ "deprecated"
  end

  test "put_option/3" do
    conn0 = put_option(%Conn{state: :unsent, opts: [max_attempts: 3]}, :connect_timeout, 3000)
    assert Keyword.equal?(conn0.opts, connect_timeout: 3000, max_attempts: 3)
    conn1 = put_option(%Conn{state: :unsent, opts: [max_attempts: 3]}, :connect_timeout, 3000)
    assert Keyword.equal?(conn1.opts, connect_timeout: 3000, max_attempts: 3)

    assert_raise AlreadySentError, "the request was already sent", fn ->
      put_option(%Conn{state: :sent}, :connect_timeout, 3000)
    end
  end

  test "deprecated put_req_body/1" do
    assert capture_io(:stderr, fn ->
             assert put_req_body("new") == %Conn{state: :unsent, req_body: "new"}
           end) =~ "deprecated"
  end

  test "put_req_body/2 test" do
    assert put_req_body(%Conn{state: :unsent, req_body: "old"}, "new") == %Conn{
             state: :unsent,
             req_body: "new"
           }

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

  test "get_resp_headers/1" do
    assert get_resp_headers(%Conn{state: :sent, resp_headers: %{"server" => "Microsoft-IIS/8.5"}}) ==
             %{"server" => "Microsoft-IIS/8.5"}

    assert_raise NotSentError, "the request was not sent yet", fn ->
      get_resp_headers(%Conn{state: :unsent})
    end
  end

  test "deprecated: get_resp_header/1 and get_resp_header/2 with nil key" do
    assert capture_io(:stderr, fn ->
             assert get_resp_header(%Conn{
                      state: :sent,
                      resp_headers: %{"server" => "Microsoft-IIS/8.5"}
                    }) ==
                      %{"server" => "Microsoft-IIS/8.5"}

             assert get_resp_header(
                      %Conn{state: :sent, resp_headers: %{"server" => "Microsoft-IIS/8.5"}},
                      nil
                    ) ==
                      %{"server" => "Microsoft-IIS/8.5"}

             assert_raise NotSentError, "the request was not sent yet", fn ->
               get_resp_header(%Conn{state: :unsent})
             end
           end) =~ "deprecated"
  end

  test "get_resp_header/2" do
    assert get_resp_header(
             %Conn{state: :sent, resp_headers: %{"server" => "Microsoft-IIS/8.5"}},
             "Server"
           ) ==
             "Microsoft-IIS/8.5"

    assert get_resp_header(
             %Conn{state: :sent, resp_headers: %{"server" => "Microsoft-IIS/8.5"}},
             "Server1"
           ) ==
             nil

    assert_raise NotSentError, "the request was not sent yet", fn ->
      get_resp_header(%Conn{state: :unsent}, "Server")
    end
  end

  test "get_req_headers/1" do
    assert get_req_headers(%Conn{req_headers: %{"server" => "Microsoft-IIS/8.5"}}) ==
             %{"server" => "Microsoft-IIS/8.5"}
  end

  test "deprecated: get_req_header/1" do
    assert capture_io(:stderr, fn ->
             assert get_req_header(%Conn{req_headers: %{"server" => "Microsoft-IIS/8.5"}}) ==
                      %{"server" => "Microsoft-IIS/8.5"}
           end) =~ "deprecated"
  end

  test "get_req_header/2" do
    assert capture_io(:stderr, fn ->
             assert get_req_header(%Conn{req_headers: %{"server" => "Microsoft-IIS/8.5"}}, nil) ==
                      %{"server" => "Microsoft-IIS/8.5"}
           end) =~ "deprecated"

    assert get_req_header(%Conn{req_headers: %{"server" => "Microsoft-IIS/8.5"}}, "Server") ==
             "Microsoft-IIS/8.5"

    assert get_req_header(%Conn{req_headers: %{"server" => "Microsoft-IIS/8.5"}}, "Server1") ==
             nil
  end

  test "get_resp_body/1" do
    assert get_resp_body(%Conn{state: :sent, resp_body: "I'm ok"}) == "I'm ok"

    assert_raise NotSentError, "the request was not sent yet", fn ->
      get_resp_body(%Conn{state: :unsent})
    end
  end

  test "get_resp_body/2" do
    assert get_resp_body(%Conn{state: :sent, resp_body: %{"foo" => %{"addr" => "China"}}}, [
             "foo",
             "addr"
           ]) == "China"

    func = fn body -> String.split(body, ~r{,}) end
    assert get_resp_body(%Conn{state: :sent, resp_body: "1,2,3"}, func) == ["1", "2", "3"]

    assert_raise NotSentError, "the request was not sent yet", fn ->
      get_resp_body(%Conn{state: :unsent, resp_body: %{"foo" => "bar"}}, "foo")
    end
  end

  test "put_private/3" do
    assert put_private(%Conn{}, :user_id, "zhongwencool") == %Conn{
             private: %{user_id: "zhongwencool"}
           }
  end

  test "get_private/2" do
    assert get_private(%Conn{}, :user_id) == nil
    assert get_private(%Conn{private: %{user_id: "zhongwencool"}}, :user_id) == "zhongwencool"
  end
end
