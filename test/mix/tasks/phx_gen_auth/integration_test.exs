Code.require_file("../../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Phx.Gen.Auth.IntegrationTest do
  use ExUnit.Case

  import MixHelper

  alias Mix.Tasks.Phx.New

  @moduletag timeout: :infinity
  @moduletag :integration

  test "single project with postgres, default schema and context names" do
    in_test_app("demo", fn ->
      mix_run!(["phx.gen.auth", "Accounts", "User", "users"])

      assert_file("test/demo/accounts_test.exs", fn file ->
        assert file =~ ~r/use Demo\.DataCase, async: true$/m
      end)

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
      mix_run!(["phx.gen.auth", "Users", "Admin", "admin"])
      mix_deps_get_and_compile()

      assert_no_compilation_warnings()
      assert_mix_test_succeeds()
    end)
  end

  test "single project with web module" do
    in_test_app("single_app_with_web_module", fn ->
      mix_run!(~w(phx.gen.auth Accounts User users --web Warehouse))
      mix_deps_get_and_compile()

      assert_no_compilation_warnings()
      assert_mix_test_succeeds()
    end)
  end

  test "single project with mysql" do
    in_test_app("demo_mysql", ~w(--database mysql), fn ->
      mix_run!(["phx.gen.auth", "Accounts", "User", "users"])

      assert_file("test/demo_mysql/accounts_test.exs", fn file ->
        assert file =~ ~r/use DemoMysql\.DataCase$/m
      end)

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
      mix_run!(["phx.gen.auth", "Accounts", "User", "users"])

      assert_file("test/demo_mssql/accounts_test.exs", fn file ->
        assert file =~ ~r/use DemoMssql\.DataCase$/m
      end)

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
        mix_run!(["phx.gen.auth", "Accounts", "User", "users"])
      end)

      mix_deps_get_and_compile()

      assert_no_compilation_warnings()
      assert_mix_test_succeeds()
    end)
  end

  defp in_test_app(app_name, opts \\ [], function) when is_list(opts) when is_function(function, 0) do
    in_test_apps(fn ->
      test_app_path = Path.join(test_apps_path(), app_name)

      delete_old_app(test_app_path)

      generate_new_app(app_name, opts)

      File.cd!(test_app_path, fn ->
        with_cached_build_and_deps(app_name, fn ->
          inject_phx_gen_auth_dependency()
          mix_deps_get_and_compile()
          ecto_drop()
          git_init_and_commit()
          function.()
        end)
      end)
    end)
  end

  defp in_test_umbrella_app(app_name, opts \\ [], function) when is_list(opts) when is_function(function, 0) do
    in_test_apps(fn ->
      umbrella_app_name = "#{app_name}_umbrella"
      test_app_path = Path.join(test_apps_path(), umbrella_app_name)

      delete_old_app(test_app_path)

      generate_new_app(app_name, ["--umbrella" | opts])

      File.cd!(test_app_path, fn ->
        with_cached_build_and_deps(umbrella_app_name, fn ->
          inject_phx_gen_auth_dependency_in_umbrella(app_name)
          mix_deps_get_and_compile()
          ecto_drop()
          git_init_and_commit()
          function.()
        end)
      end)
    end)
  end

  defp in_test_apps(function) do
    path = test_apps_path()
    File.mkdir_p!(path)
    File.cd!(path, function)
  end

  defp with_cached_build_and_deps(app_name, function) do
    cache_path = Path.join(test_apps_path(), "cache")
    cache_archive_path = Path.join(cache_path, "#{app_name}.tar") |> Path.expand()

    try do
      if File.exists?(cache_archive_path) do
        :ok = :erl_tar.extract(cache_archive_path)
      end

      function.()
    after
      paths =
        Path.wildcard("{_build,deps}/**", match_dot: true)
        |> Enum.filter(&(!File.dir?(&1)))
        |> Enum.map(&to_charlist/1)

      :ok = File.mkdir_p!(cache_path)
      :ok = :erl_tar.create(cache_archive_path, paths)
    end
  end

  defp test_apps_path do
    Path.expand("../../../../test_apps", __DIR__)
  end

  defp delete_old_app(test_app_path) do
    File.rm_rf!(test_app_path)
  end

  defp generate_new_app(app_name, opts) when is_list(opts) do
    # The shell asks to install deps.
    # We will politely say not.
    send(self(), {:mix_shell_input, :yes?, false})

    New.run([app_name | opts])
  end

  defp inject_phx_gen_auth_dependency do
    file_path = "mix.exs"
    file = File.read!(file_path)

    inject = """
    {:phx_gen_auth, path: "../..", only: [:dev, :test], runtime: false},
    """

    anchor = """
    {:phoenix, github: "phoenixframework/phoenix", override: true},
    """

    unless String.contains?(file, inject) do
      new_file = String.replace(file, anchor, "#{anchor}\n      #{inject}")

      File.write!(file_path, new_file)
    end
  end

  defp inject_phx_gen_auth_dependency_in_umbrella(app_name) do
    file_path = Path.join(["apps", "#{app_name}_web", "mix.exs"])
    file = File.read!(file_path)

    inject = """
    {:phx_gen_auth, path: "../../../../", only: [:dev, :test], runtime: false},
    """

    anchor = """
    {:phoenix, github: "phoenixframework/phoenix", override: true},
    """

    unless String.contains?(file, inject) do
      new_file = String.replace(file, anchor, "#{anchor}\n      #{inject}")

      File.write!(file_path, new_file)
    end
  end

  defp git_init_and_commit() do
    {_, 0} = System.cmd("git", ["init", "."])
    {_, 0} = System.cmd("git", ["add", "."])
    {_, 0} = System.cmd("git", ["config", "user.email", "test@test.com"])
    {_, 0} = System.cmd("git", ["config", "user.name", "Integration Tester"])
    {_, 0} = System.cmd("git", ["commit", "-m", "Initial project"])

    :ok
  end

  defp mix_deps_get_and_compile do
    mix_run!(["do", "deps.get", "--no-archives-check,", "deps.compile"])
    :ok
  end

  defp ecto_drop, do: mix_run!(["ecto.drop"])

  defp mix_run!(args) when is_list(args) do
    {_, 0} = System.cmd("mix", args, env: [{"MIX_ENV", "test"}], into: IO.stream(:stdio, :line))
    :ok
  end

  defp assert_mix_test_succeeds do
    case System.cmd("mix", ["test"]) do
      {_output, 0} ->
        :ok

      {output, exit_code} ->
        flunk("""
        mix test failed with exit code: #{inspect(exit_code)}

        #{output}

        """)
    end
  end

  defp assert_no_compilation_warnings do
    {_, 0} =
      System.cmd(
        "mix",
        ["compile", "--warnings-as-errors"],
        env: [{"MIX_ENV", "test"}],
        into: IO.stream(:stdio, :line)
      )

    :ok
  end
end
