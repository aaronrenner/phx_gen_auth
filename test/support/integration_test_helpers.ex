defmodule Phx.Gen.Auth.TestSupport.IntegrationTestHelpers do
  require Logger

  import ExUnit.Assertions

  alias Mix.Tasks.Phx.New
  alias Mix.Phx.Gen.Auth.Injector

  def in_test_app(app_name, opts \\ [], function) when is_list(opts) when is_function(function, 0) do
    in_test_apps(fn ->
      test_app_path = Path.join(test_apps_path(), app_name)

      delete_old_app(test_app_path)

      generate_new_app(app_name, opts)

      File.cd!(test_app_path, fn ->
        with_cached_build_and_deps(app_name, fn ->
          inject_phx_gen_auth_dependency()
          mix_deps_get_and_compile()
          unless "--no-ecto" in opts, do: ecto_drop()
          git_init_and_commit()
          function.()
        end)
      end)
    end)
  end

  def in_test_umbrella_app(app_name, opts \\ [], function) when is_list(opts) when is_function(function, 0) do
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

  def in_test_mix_app(app_name, opts \\ [], function) when is_list(opts) when is_function(function, 0) do
    in_test_apps(fn ->
      test_app_path = Path.join(test_apps_path(), app_name)

      delete_old_app(test_app_path)

      mix_run!(~w(new #{app_name}))

      File.cd!(test_app_path, fn ->
        with_cached_build_and_deps(app_name, fn ->
          inject_phx_gen_auth_dependency()
          mix_deps_get_and_compile()
          git_init_and_commit()
          function.()
        end)
      end)
    end)
  end

  def in_test_apps(function) do
    path = test_apps_path()
    File.mkdir_p!(path)
    File.cd!(path, function)
  end

  def mix_deps_get_and_compile do
    mix_run!(["do", "deps.get", "--no-archives-check,", "deps.compile"])
  end

  def mix_run!(args) when is_list(args) do
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

  def mix_run(args) when is_list(args) do
    if ExUnit.configuration() |> Keyword.get(:trace) do
      Logger.debug("Running mix #{Enum.join(args, " ")}")
    end

    System.cmd("mix", args, env: [{"MIX_ENV", "test"}], stderr_to_stdout: true)
  end

  def assert_mix_test_succeeds do
    mix_run!(~w(test))
  end

  def assert_no_compilation_warnings do
    mix_run!(~w(compile --warnings-as-errors))
  end

  def inject_compilation_error(path) do
    path
    |> File.read!()
    |> Kernel.<>("boom")
    |> write_file!(path)
  end

  defp write_file!(content, path) do
    File.write!(path, content)
  end

  def revert_to_clean_phoenix_app do
    {_, 0} = System.cmd("git", ["clean", "-df"])
    {_, 0} = System.cmd("git", ["checkout", "--", "."])

    :ok
  end

  defp with_cached_build_and_deps(app_name, function) do
    cache_path = Path.join(test_apps_path(), ".cache")
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
    Path.expand("../../test_apps", __DIR__)
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
    inject = ~s|{:phx_gen_auth, path: "../..", only: [:dev, :test], runtime: false}|

    inject_dependency(file_path, inject)
  end

  defp inject_phx_gen_auth_dependency_in_umbrella(app_name) do
    file_path = Path.join(["apps", "#{app_name}_web", "mix.exs"])
    inject = ~s|{:phx_gen_auth, path: "../../../../", only: [:dev, :test], runtime: false}|

    inject_dependency(file_path, inject)
  end

  defp inject_dependency(file_path, dependency) do
    file = File.read!(file_path)
    {:ok, new_file} = Injector.inject_mix_dependency(file, dependency)
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

  defp ecto_drop, do: mix_run!(["ecto.drop"])
end
