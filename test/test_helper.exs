Application.ensure_all_started(:mimic)

Mimic.copy(:httpc)
Mimic.copy(:hackney)
Mimic.copy(:ibrowse)

ExUnit.start()

Code.load_file("test/maxwell/adapter/adapter_test_helper.exs")
Code.load_file("test/maxwell/middleware/middleware_test_helper.exs")
