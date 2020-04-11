defmodule Phx.Gen.Auth.IntegrationTests.BasicMixAppTest do
  use ExUnit.Case, async: true

  import Phx.Gen.Auth.TestSupport.IntegrationTestHelpers

  require Logger

  @moduletag timeout: :infinity
  @moduletag :integration

  setup do
    test_app_path = setup_test_mix_app("basic_mix")
    [test_app_path: test_app_path]
  end

  test "errors in basic mix project", %{test_app_path: test_app_path} do
    {output, 1} = mix_run(~w(phx.gen.auth Accounts User users), cd: test_app_path)
    # TODO: figure out how to return a better error here
    assert output =~ "mix phx.gen.auth requires ecto_sql"
  end
end
