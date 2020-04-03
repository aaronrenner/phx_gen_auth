Code.require_file("../../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Phx.Gen.Auth.IntegrationTest do
  use ExUnit.Case

  import MixHelper

  alias Mix.Tasks.Phx.New
  alias Mix.Phx.Gen.Auth.Injector

  require Logger

  @moduletag timeout: :infinity
  @moduletag :integration

  test "single project with postgres, default schema and context names" do
    in_test_app("demo", fn ->
      mix_run!(~w(phx.gen.auth Accounts User users))

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

      assert_no_compilation_warnings()
      assert_mix_test_succeeds()
    end)
  end

  test "single project with mysql" do
    in_test_app("demo_mysql", ~w(--database mysql), fn ->
      mix_run!(~w(phx.gen.auth Accounts User users))

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
      mix_run!(~w(phx.gen.auth Accounts User users))

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
        mix_run!(~w(phx.gen.auth Accounts User users))
      end)

      mix_deps_get_and_compile()

      assert_no_compilation_warnings()
      assert_mix_test_succeeds()
    end)
  end

  test "error messages" do
    in_test_umbrella_app("stormy_day", fn ->
      assert {output, 1} = mix_run(~w(phx.gen.auth Accounts User users))
      assert output =~ "mix phx.gen.auth can only be run inside an application directory"

      with_compilation_error("apps/stormy_day/lib/stormy_day/repo.ex", fn ->
        File.cd!("apps/stormy_day_web", fn ->
          {output, 1} = mix_run(~w(phx.gen.auth Accounts User users))
          assert output =~ "Compilation error in file"
        end)
      end)

      with_file_removed("apps/stormy_day/lib/stormy_day/repo.ex", fn ->
        File.cd!("apps/stormy_day_web", fn ->
          {output, 1} = mix_run(~w(phx.gen.auth Accounts User users))
          assert output =~ "Unable to find StormyDay.Repo"
        end)
      end)
    end)
  end

  defp with_compilation_error(path, function) do
    with_file_content_change(path, & Kernel.<>(&1, "boom"), function)
  end

  defp with_file_removed(path, function) when is_function(function, 0) do
    content = File.read!(path)

    try do
      File.rm!(path)

      function.()
    after
      File.write!(path, content)
    end
  end

  defp with_file_content_change(path, new_content_function, function) when is_function(new_content_function, 1) and is_function(function, 0) do
    original_content = File.read!(path)
    new_content = new_content_function.(original_content)

    try do
      File.write!(path, new_content)

      function.()
    after
      File.write!(path, original_content)
    end
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

    inject = ~s|{:phx_gen_auth, path: "../..", only: [:dev, :test], runtime: false}|

    {:ok, new_file} = Injector.inject_mix_dependency(file, inject)
    File.write!(file_path, new_file)
  end

  defp inject_phx_gen_auth_dependency_in_umbrella(app_name) do
    file_path = Path.join(["apps", "#{app_name}_web", "mix.exs"])
    file = File.read!(file_path)

    inject = ~s|{:phx_gen_auth, path: "../../../../", only: [:dev, :test], runtime: false}|

    {:ok, new_file} = Injector.inject_mix_dependency(file, inject)
    File.write!(file_path, new_file)
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
  end

  defp ecto_drop, do: mix_run!(["ecto.drop"])

  defp mix_run!(args) when is_list(args) do
    case mix_run(args) do
      {_, 0} ->
        :ok

      {output, exit_code} ->
        flunk("""
        mix command failed with exit code: #{inspect(exit_code)}

        mix #{Enum.join(args, " ")}

        #{output}

        """)
    end
  end

  defp mix_run(args) when is_list(args) do
    Logger.debug("Running mix #{Enum.join(args, " ")}")
    System.cmd("mix", args, env: [{"MIX_ENV", "test"}], stderr_to_stdout: true)
  end

  defp assert_mix_test_succeeds do
    mix_run!(~w(test))
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
