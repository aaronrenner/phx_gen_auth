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

    assert_file(Path.join(test_app_path, "config/test.exs"), fn file ->
      assert file =~ "config :bcrypt_elixir, :log_rounds, 1"
    end)

    assert_file(Path.join(test_app_path, "lib/demo/accounts/user.ex"), fn file ->
      assert file =~ "Bcrypt.verify_pass(password, hashed_password)"
    end)

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

    [migration] =
      test_app_path
      |> Path.join("priv/repo/migrations/*_create_user_auth_tables.exs")
      |> Path.wildcard()

    assert_file(migration, fn file ->
      assert file =~ "create table(:users)"
      assert file =~ "create table(:user_tokens)"
      refute file =~ "add :id, :binary_id, primary_key: true"
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

  test "supports binary_id option", %{test_app_path: test_app_path} do
    mix_run!(~w(phx.gen.auth Accounts User users --binary-id), cd: test_app_path)

    [migration] =
      test_app_path
      |> Path.join("priv/repo/migrations/*_create_user_auth_tables.exs")
      |> Path.wildcard()

    assert_file(migration, fn file ->
      assert file =~ "create table(:users, primary_key: false)"
      assert file =~ "create table(:user_tokens, primary_key: false)"
      assert file =~ "add :id, :binary_id, primary_key: true"
    end)

    mix_deps_get_and_compile(test_app_path)

    assert_no_compilation_warnings(test_app_path)
    assert_mix_test_succeeds(test_app_path)
  end

  test "with pbkdf2 as the hashing library", %{test_app_path: test_app_path} do
    mix_run!(~w(phx.gen.auth Accounts User users --hashing-lib pbkdf2), cd: test_app_path)

    assert_file(Path.join(test_app_path, "lib/demo/accounts/user.ex"), fn file ->
      assert file =~ "Pbkdf2.verify_pass(password, hashed_password)"
    end)

    assert_file(Path.join(test_app_path, "config/test.exs"), fn file ->
      assert file =~ "config :pbkdf2_elixir, :rounds, 1"
    end)

    mix_deps_get_and_compile(test_app_path)

    assert_no_compilation_warnings(test_app_path)
    assert_mix_test_succeeds(test_app_path)
  end

  test "with argon2 as the hashing library", %{test_app_path: test_app_path} do
    mix_run!(~w(phx.gen.auth Accounts User users --hashing-lib argon2), cd: test_app_path)

    assert_file(Path.join(test_app_path, "lib/demo/accounts/user.ex"), fn file ->
      assert file =~ "Argon2.verify_pass(password, hashed_password)"
    end)

    assert_file(Path.join(test_app_path, "config/test.exs"), fn file ->
      assert file =~ """
             config :argon2_elixir,
               t_cost: 1,
               m_cost: 8
             """
    end)

    mix_deps_get_and_compile(test_app_path)

    assert_no_compilation_warnings(test_app_path)
    assert_mix_test_succeeds(test_app_path)
  end
end
