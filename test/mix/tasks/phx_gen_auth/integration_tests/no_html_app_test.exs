defmodule Phx.Gen.Auth.IntegrationTests.NoHtmlAppTest do
  use ExUnit.Case, async: true

  import Phx.Gen.Auth.TestSupport.IntegrationTestHelpers

  require Logger

  @moduletag timeout: :infinity
  @moduletag :integration

  setup do
    test_app_path = setup_test_app("app_with_no_html", ~w(--no-html))
    [test_app_path: test_app_path]
  end

  test "errors in phoenix project with --no-html", %{test_app_path: test_app_path} do
    assert {output, 1} = mix_run(~w(phx.gen.auth Accounts User users), cd: test_app_path)
    assert output =~ "mix phx.gen.auth requires phoenix_html"
  end
end
