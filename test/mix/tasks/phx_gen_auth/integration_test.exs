Code.require_file("../../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Phx.Gen.Auth.IntegrationTest do
  use ExUnit.Case

  import MixHelper
  import Phx.Gen.Auth.TestSupport.IntegrationTestHelpers

  require Logger

  @moduletag timeout: :infinity
  @moduletag :integration

  test "single project with postgres, default schema and context names" do
    in_test_app("demo", fn ->
      mix_run!(~w(phx.gen.auth Accounts User users))

      assert_file("lib/demo_web/controllers/user_confirmation_controller.ex")
      assert_file("lib/demo_web/controllers/user_reset_password_controller.ex")
      assert_file("lib/demo_web/controllers/user_registration_controller.ex")
      assert_file("lib/demo_web/controllers/user_session_controller.ex")
      assert_file("lib/demo_web/controllers/user_settings_controller.ex")

      assert_file("test/demo_web/controllers/user_auth_test.exs", fn file ->
        assert file =~ ~r/use DemoWeb\.ConnCase, async: true$/m
      end)

      assert_file("test/demo_web/controllers/user_confirmation_controller_test.exs", fn file ->
        assert file =~ ~r/use DemoWeb\.ConnCase, async: true$/m
      end)

      assert_file("test/demo_web/controllers/user_registration_controller_test.exs", fn file ->
        assert file =~ ~r/use DemoWeb\.ConnCase, async: true$/m
      end)

      assert_file("test/demo_web/controllers/user_reset_password_controller_test.exs", fn file ->
        assert file =~ ~r/use DemoWeb\.ConnCase, async: true$/m
      end)

      assert_file("test/demo_web/controllers/user_session_controller_test.exs", fn file ->
        assert file =~ ~r/use DemoWeb\.ConnCase, async: true$/m
      end)

      assert_file("test/demo_web/controllers/user_settings_controller_test.exs", fn file ->
        assert file =~ ~r/use DemoWeb\.ConnCase, async: true$/m
      end)

      mix_deps_get_and_compile()

      assert_no_compilation_warnings()
      assert_mix_test_succeeds()
    end)
  end

  test "single project with alternative schema and context names" do
    in_test_app("single_app_with_alternative_context_schema", fn ->
      mix_run!(~w(phx.gen.auth Users Admin admin))
      mix_deps_get_and_compile()

      assert_no_compilation_warnings()
      assert_mix_test_succeeds()
    end)
  end

  test "single project with web module" do
    in_test_app("single_app_with_web_module", fn ->
      mix_run!(~w(phx.gen.auth Accounts User users --web Warehouse))
      mix_deps_get_and_compile()

      assert_file("lib/single_app_with_web_module_web/controllers/warehouse/user_confirmation_controller.ex")
      assert_file("lib/single_app_with_web_module_web/controllers/warehouse/user_reset_password_controller.ex")
      assert_file("lib/single_app_with_web_module_web/controllers/warehouse/user_registration_controller.ex")
      assert_file("lib/single_app_with_web_module_web/controllers/warehouse/user_session_controller.ex")
      assert_file("lib/single_app_with_web_module_web/controllers/warehouse/user_settings_controller.ex")

      assert_no_compilation_warnings()
      assert_mix_test_succeeds()
    end)
  end

  test "single project with mysql" do
    in_test_app("demo_mysql", ~w(--database mysql), fn ->
      mix_run!(~w(phx.gen.auth Accounts User users))

      assert_file("test/demo_mysql_web/controllers/user_auth_test.exs", fn file ->
        assert file =~ ~r/use DemoMysqlWeb\.ConnCase$/m
      end)

      assert_file("test/demo_mysql_web/controllers/user_confirmation_controller_test.exs", fn file ->
        assert file =~ ~r/use DemoMysqlWeb\.ConnCase$/m
      end)

      assert_file("test/demo_mysql_web/controllers/user_registration_controller_test.exs", fn file ->
        assert file =~ ~r/use DemoMysqlWeb\.ConnCase$/m
      end)

      assert_file("test/demo_mysql_web/controllers/user_reset_password_controller_test.exs", fn file ->
        assert file =~ ~r/use DemoMysqlWeb\.ConnCase$/m
      end)

      assert_file("test/demo_mysql_web/controllers/user_session_controller_test.exs", fn file ->
        assert file =~ ~r/use DemoMysqlWeb\.ConnCase$/m
      end)

      assert_file("test/demo_mysql_web/controllers/user_settings_controller_test.exs", fn file ->
        assert file =~ ~r/use DemoMysqlWeb\.ConnCase$/m
      end)

      mix_deps_get_and_compile()

      assert_no_compilation_warnings()
      assert_mix_test_succeeds()
    end)
  end

  test "single project with mssql" do
    in_test_app("demo_mssql", ~w(--database mssql), fn ->
      mix_run!(~w(phx.gen.auth Accounts User users))

      assert_file("test/demo_mssql_web/controllers/user_auth_test.exs", fn file ->
        assert file =~ ~r/use DemoMssqlWeb\.ConnCase$/m
      end)

      assert_file("test/demo_mssql_web/controllers/user_confirmation_controller_test.exs", fn file ->
        assert file =~ ~r/use DemoMssqlWeb\.ConnCase$/m
      end)

      assert_file("test/demo_mssql_web/controllers/user_registration_controller_test.exs", fn file ->
        assert file =~ ~r/use DemoMssqlWeb\.ConnCase$/m
      end)

      assert_file("test/demo_mssql_web/controllers/user_reset_password_controller_test.exs", fn file ->
        assert file =~ ~r/use DemoMssqlWeb\.ConnCase$/m
      end)

      assert_file("test/demo_mssql_web/controllers/user_session_controller_test.exs", fn file ->
        assert file =~ ~r/use DemoMssqlWeb\.ConnCase$/m
      end)

      assert_file("test/demo_mssql_web/controllers/user_settings_controller_test.exs", fn file ->
        assert file =~ ~r/use DemoMssqlWeb\.ConnCase$/m
      end)

      mix_deps_get_and_compile()

      assert_no_compilation_warnings()
      assert_mix_test_succeeds()
    end)
  end

  test "new umbrella project with default context and names" do
    in_test_umbrella_app("rainy_day", fn ->
      File.cd!("apps/rainy_day_web", fn ->
        mix_run!(~w(phx.gen.auth Accounts User users))
      end)

      mix_deps_get_and_compile()

      assert_no_compilation_warnings()
      assert_mix_test_succeeds()
    end)
  end

  test "error messages" do
    in_test_umbrella_app("rainy_day", fn ->
      assert {output, 1} = mix_run(~w(phx.gen.auth Accounts User users))
      assert output =~ "mix phx.gen.auth can only be run inside an application directory"

      inject_compilation_error("apps/rainy_day/lib/rainy_day/repo.ex")

      File.cd!("apps/rainy_day_web", fn ->
        {output, 1} = mix_run(~w(phx.gen.auth Accounts User users))
        assert output =~ "Compilation error in file"
      end)

      revert_to_clean_phoenix_app()

      File.rm!("apps/rainy_day/lib/rainy_day/repo.ex")

      File.cd!("apps/rainy_day_web", fn ->
        {output, 1} = mix_run(~w(phx.gen.auth Accounts User users))
        assert output =~ "Unable to find RainyDay.Repo"
      end)
    end)
  end

  test "errors in basic mix project" do
    in_test_mix_app("basic_mix", fn ->
      {output, 1} = mix_run(~w(phx.gen.auth Accounts User users))
      # TODO: figure out how to return a better error here
      assert output =~ "mix phx.gen.auth requires ecto_sql"
    end)
  end

  test "errors in phoenix project with --no-ecto" do
    in_test_app("app_with_no_ecto", ~w(--no-ecto), fn ->
      assert {output, 1} = mix_run(~w(phx.gen.auth Accounts User users))
      # TODO: come up with a better error here
      assert output =~ "mix phx.gen.auth requires ecto_sql"
    end)
  end
end
