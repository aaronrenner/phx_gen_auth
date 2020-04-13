defmodule Phx.Gen.Auth.IntegrationTests.DefaultAppTest do
  use ExUnit.Case, async: true

  import Phx.Gen.Auth.TestSupport.IntegrationTestHelpers

  alias Mix.Phx.Gen.Auth.Injector

  require Logger

  @moduletag timeout: :infinity
  @moduletag :integration

  setup do
    test_app_path = setup_test_app("demo")
    [test_app_path: test_app_path]
  end

  test "single project with postgres, default schema and context names", %{test_app_path: test_app_path} do
    mix_run!(~w(phx.gen.auth Accounts User users), cd: test_app_path)

    assert_file(Path.join(test_app_path, "lib/demo_web/controllers/user_confirmation_controller.ex"))
    assert_file(Path.join(test_app_path, "lib/demo_web/controllers/user_reset_password_controller.ex"))
    assert_file(Path.join(test_app_path, "lib/demo_web/controllers/user_registration_controller.ex"))
    assert_file(Path.join(test_app_path, "lib/demo_web/controllers/user_session_controller.ex"))
    assert_file(Path.join(test_app_path, "lib/demo_web/controllers/user_settings_controller.ex"))

    assert_file(Path.join(test_app_path, "test/demo_web/controllers/user_auth_test.exs"), fn file ->
      assert file =~ ~r/use DemoWeb\.ConnCase, async: true$/m
    end)

    assert_file(Path.join(test_app_path, "test/demo_web/controllers/user_confirmation_controller_test.exs"), fn file ->
      assert file =~ ~r/use DemoWeb\.ConnCase, async: true$/m
    end)

    assert_file(Path.join(test_app_path, "test/demo_web/controllers/user_registration_controller_test.exs"), fn file ->
      assert file =~ ~r/use DemoWeb\.ConnCase, async: true$/m
    end)

    assert_file(Path.join(test_app_path, "test/demo_web/controllers/user_reset_password_controller_test.exs"), fn file ->
      assert file =~ ~r/use DemoWeb\.ConnCase, async: true$/m
    end)

    assert_file(Path.join(test_app_path, "test/demo_web/controllers/user_session_controller_test.exs"), fn file ->
      assert file =~ ~r/use DemoWeb\.ConnCase, async: true$/m
    end)

    assert_file(Path.join(test_app_path, "test/demo_web/controllers/user_settings_controller_test.exs"), fn file ->
      assert file =~ ~r/use DemoWeb\.ConnCase, async: true$/m
    end)

    assert_file(Path.join(test_app_path, "test/support/fixtures/accounts_fixtures.ex"))

    assert_file(Path.join(test_app_path, "test/support/conn_case.ex"), fn file ->
      assert file =~ "def login_user"
    end)

    mix_deps_get_and_compile(test_app_path)

    assert_no_compilation_warnings(test_app_path)
    assert_mix_test_succeeds(test_app_path)
  end

  test "single project with alternative schema and context names", %{test_app_path: test_app_path} do
    mix_run!(~w(phx.gen.auth Users Admin admin), cd: test_app_path)
    mix_deps_get_and_compile(test_app_path)

    assert_no_compilation_warnings(test_app_path)
    assert_mix_test_succeeds(test_app_path)
  end

  test "single project with web module", %{test_app_path: test_app_path} do
    mix_run!(~w(phx.gen.auth Accounts User users --web Warehouse), cd: test_app_path)
    mix_deps_get_and_compile(test_app_path)

    assert_file(Path.join(test_app_path, "lib/demo_web/controllers/warehouse/user_confirmation_controller.ex"))
    assert_file(Path.join(test_app_path, "lib/demo_web/controllers/warehouse/user_reset_password_controller.ex"))
    assert_file(Path.join(test_app_path, "lib/demo_web/controllers/warehouse/user_registration_controller.ex"))
    assert_file(Path.join(test_app_path, "lib/demo_web/controllers/warehouse/user_session_controller.ex"))
    assert_file(Path.join(test_app_path, "lib/demo_web/controllers/warehouse/user_settings_controller.ex"))

    assert_no_compilation_warnings(test_app_path)
    assert_mix_test_succeeds(test_app_path)
  end

  test "properly installs into existing context", %{test_app_path: test_app_path} do
    mix_run!(~w(phx.gen.html Accounts Company companies name), cd: test_app_path)

    modify_file(Path.join(test_app_path, "lib/demo_web/router.ex"), fn file ->
      {:ok, new_file} =
        Injector.inject_before_final_end(file, """

          scope "/", DemoWeb do
            pipe_through [:browser]

            resources "/companies", CompanyController
          end
        """)

      new_file
    end)

    assert_no_compilation_warnings(test_app_path)
    assert_mix_test_succeeds(test_app_path)

    mix_run!(~w(phx.gen.auth Accounts User users), cd: test_app_path, prompt_responses: ["Y"])
    mix_deps_get_and_compile(test_app_path)

    assert_no_compilation_warnings(test_app_path)
    assert_mix_test_succeeds(test_app_path)

    assert_file(Path.join(test_app_path, "lib/demo/accounts.ex"), fn file ->
      assert file =~ "register_user"
    end)
  end
end
