defmodule Phx.Gen.Auth.IntegrationTests.NoEctoAppTest do
  use ExUnit.Case, async: true

  import Phx.Gen.Auth.TestSupport.IntegrationTestHelpers

  require Logger

  @moduletag timeout: :infinity
  @moduletag :integration

  setup do
    test_app_path = setup_test_app("app_with_no_ecto", ~w(--no-ecto))
    [test_app_path: test_app_path]
  end

  test "errors in phoenix project with --no-ecto", %{test_app_path: test_app_path} do
    assert {output, 1} = mix_run(~w(phx.gen.auth Accounts User users), cd: test_app_path)
    # TODO: come up with a better error here
    assert output =~ "mix phx.gen.auth requires ecto_sql"
  end
end
