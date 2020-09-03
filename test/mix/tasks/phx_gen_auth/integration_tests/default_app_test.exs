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
      assert file =~ "def log_in_user"
    end)

    [migration] =
      test_app_path
      |> Path.join("priv/repo/migrations/*_create_users_auth_tables.exs")
      |> Path.wildcard()

    assert_file(migration, fn file ->
      assert file =~ "create table(:users)"
      assert file =~ "create table(:users_tokens)"
      refute file =~ "add :id, :binary_id, primary_key: true"
    end)

    mix_deps_get_and_compile(test_app_path)

    assert_no_compilation_warnings(test_app_path)
    assert_mix_test_succeeds(test_app_path)
    assert_passes_formatter_check(test_app_path)
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
      |> Path.join("priv/repo/migrations/*_create_users_auth_tables.exs")
      |> Path.wildcard()

    assert_file(migration, fn file ->
      assert file =~ "create table(:users, primary_key: false)"
      assert file =~ "create table(:users_tokens, primary_key: false)"
      assert file =~ "add :id, :binary_id, primary_key: true"
    end)

    mix_deps_get_and_compile(test_app_path)

    assert_no_compilation_warnings(test_app_path)
    assert_mix_test_succeeds(test_app_path)
    assert_passes_formatter_check(test_app_path)
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

  test "with a custom table_name", %{test_app_path: test_app_path} do
    mix_run!(~w(phx.gen.auth Ticketing User users --table ticketing_users), cd: test_app_path)

    [migration] =
      test_app_path
      |> Path.join("priv/repo/migrations/*_create_ticketing_users_auth_tables.exs")
      |> Path.wildcard()

    assert_file(migration, fn file ->
      assert file =~ "defmodule Demo.Repo.Migrations.CreateTicketingUsersAuthTables do"
      assert file =~ "create table(:ticketing_users)"
      assert file =~ "create table(:ticketing_users_tokens)"
    end)

    mix_deps_get_and_compile(test_app_path)

    assert_no_compilation_warnings(test_app_path)
    assert_mix_test_succeeds(test_app_path)
  end

  test "merges fixtures with existing fixtures", %{test_app_path: test_app_path} do
    fixtures_dir = Path.join(test_app_path, "test/support/fixtures")
    fixtures_path = Path.join(fixtures_dir, "accounts_fixtures.ex")

    existing_fixtures_content = """
    defmodule Demo.AccountsFixtures do
      @moduledoc \"\"\"
      Fixtures for Demo.Accounts
      \"\"\"

      def existing_fixture do
        :existing
      end
    end
    """

    File.mkdir_p!(fixtures_dir)
    File.write!(fixtures_path, existing_fixtures_content)

    mix_run!(~w(phx.gen.auth Accounts User users), cd: test_app_path)

    assert_file(fixtures_path, fn file ->
      assert file =~ "def existing_fixture"
      assert file =~ "def user_fixture"
    end)

    assert_passes_formatter_check(test_app_path)
  end

  test "works with windows line endings", %{test_app_path: test_app_path} do
    convert_project_line_endings(test_app_path, "\r\n")

    mix_run!(~w(phx.gen.auth Accounts User users), cd: test_app_path)

    mix_deps_get_and_compile(test_app_path)

    assert_no_compilation_warnings(test_app_path)
    assert_mix_test_succeeds(test_app_path)
  end

  defp convert_project_line_endings(test_app_path, line_ending) do
    test_app_path
    |> Path.join("{config,lib,priv,test}/**/*.{ex,exs}")
    |> Path.wildcard()
    |> Enum.each(
      &modify_file(&1, fn content ->
        String.replace(content, ~r/(\r\n|\r|\n)/, line_ending)
      end)
    )
  end
end
