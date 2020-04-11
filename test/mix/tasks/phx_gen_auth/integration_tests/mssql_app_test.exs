defmodule Phx.Gen.Auth.IntegrationTests.MssqlAppTest do
  use ExUnit.Case, async: true

  import Phx.Gen.Auth.TestSupport.IntegrationTestHelpers

  require Logger

  @moduletag timeout: :infinity
  @moduletag :integration

  setup do
    test_app_path = setup_test_app("demo_mssql", ~w(--database mssql))
    [test_app_path: test_app_path]
  end

  test "single project with mssql", %{test_app_path: test_app_path} do
    mix_run!(~w(phx.gen.auth Accounts User users), cd: test_app_path)

    assert_file(Path.join(test_app_path, "test/demo_mssql_web/controllers/user_auth_test.exs"), fn file ->
      assert file =~ ~r/use DemoMssqlWeb\.ConnCase$/m
    end)

    assert_file(Path.join(test_app_path, "test/demo_mssql_web/controllers/user_confirmation_controller_test.exs"), fn file ->
      assert file =~ ~r/use DemoMssqlWeb\.ConnCase$/m
    end)

    assert_file(Path.join(test_app_path, "test/demo_mssql_web/controllers/user_registration_controller_test.exs"), fn file ->
      assert file =~ ~r/use DemoMssqlWeb\.ConnCase$/m
    end)

    assert_file(Path.join(test_app_path, "test/demo_mssql_web/controllers/user_reset_password_controller_test.exs"), fn file ->
      assert file =~ ~r/use DemoMssqlWeb\.ConnCase$/m
    end)

    assert_file(Path.join(test_app_path, "test/demo_mssql_web/controllers/user_session_controller_test.exs"), fn file ->
      assert file =~ ~r/use DemoMssqlWeb\.ConnCase$/m
    end)

    assert_file(Path.join(test_app_path, "test/demo_mssql_web/controllers/user_settings_controller_test.exs"), fn file ->
      assert file =~ ~r/use DemoMssqlWeb\.ConnCase$/m
    end)

    mix_deps_get_and_compile(test_app_path)

    assert_no_compilation_warnings(test_app_path)
    assert_mix_test_succeeds(test_app_path)
  end
end
