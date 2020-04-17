defmodule Phx.Gen.Auth.TestSupport.IntegrationTestHelpers do
  require Logger

  import ExUnit.Assertions

  alias Mix.Phx.Gen.Auth.Injector
  alias Phx.Gen.Auth.TestSupport.IntegrationTestHelpers.MixTaskServer

  def setup_test_app(app_name, opts \\ []) when is_list(opts) do
    File.mkdir_p!(test_apps_path())
    test_app_path = Path.join(test_apps_path(), app_name)

    if File.exists?(test_app_path) do
      revert_to_clean_phoenix_app(test_app_path)
      mix_deps_get_and_compile(test_app_path)
    else
      generate_new_app(app_name, opts)

      inject_phx_gen_auth_dependency(test_app_path)
      mix_deps_get_and_compile(test_app_path)
      git_init_and_commit(test_app_path)
    end

    unless "--no-ecto" in opts, do: ecto_drop(test_app_path)

    test_app_path
  end

  def setup_test_umbrella_app(app_name, opts \\ []) when is_list(opts) do
    File.mkdir_p!(test_apps_path())
    umbrella_app_name = "#{app_name}_umbrella"
    test_app_path = Path.join(test_apps_path(), umbrella_app_name)

    if File.exists?(test_app_path) do
      revert_to_clean_phoenix_app(test_app_path)
      mix_deps_get_and_compile(test_app_path)
    else
      generate_new_app(app_name, ["--umbrella" | opts])

      inject_phx_gen_auth_dependency_in_umbrella(test_app_path, app_name)
      mix_deps_get_and_compile(test_app_path)
      git_init_and_commit(test_app_path)
    end

    unless "--no-ecto" in opts, do: ecto_drop(test_app_path)

    test_app_path
  end

  def setup_test_mix_app(app_name, opts \\ []) when is_list(opts) do
    File.mkdir_p!(test_apps_path())
    test_app_path = Path.join(test_apps_path(), app_name)

    if File.exists?(test_app_path) do
      revert_to_clean_phoenix_app(test_app_path)
      mix_deps_get_and_compile(test_app_path)
    else
      mix_run!(~w(new #{app_name}), cd: test_apps_path())

      inject_phx_gen_auth_dependency(test_app_path)
      mix_deps_get_and_compile(test_app_path)
      git_init_and_commit(test_app_path)
    end

    test_app_path
  end

  def mix_deps_get_and_compile(app_path) do
    mix_run!(["do", "deps.get", "--no-archives-check,", "compile"], cd: app_path)
  end

  def mix_run!(args, opts \\ []) when is_list(args) and is_list(opts) do
    case mix_run(args, opts) do
      {output, 0} ->
        output

      {output, exit_code} ->
        flunk("""
        mix command failed with exit code: #{inspect(exit_code)}

        mix #{Enum.join(args, " ")}

        #{output}

        """)
    end
  end

  def mix_run(args, opts \\ []) when is_list(args) and is_list(opts) do
    if ExUnit.configuration() |> Keyword.get(:trace) do
      Logger.debug("Running mix #{Enum.join(args, " ")}")
    end

    MixTaskServer.run(args, opts)
  end

  def assert_mix_test_succeeds(app_path) do
    mix_run!(~w(test), cd: app_path)
  end

  def assert_no_compilation_warnings(app_path) do
    mix_run!(~w(compile --force --warnings-as-errors), cd: app_path)
  end

  def assert_passes_formatter_check(app_path) do
    mix_run!(~w(format --check-formatted), cd: app_path)
  end

  def assert_file(file) do
    assert File.regular?(file), "Expected #{file} to exist, but does not"
  end

  def refute_file(file) do
    refute File.regular?(file), "Expected #{file} to not exist, but it does"
  end

  def assert_file(file, match) do
    cond do
      is_list(match) ->
        assert_file(file, &Enum.each(match, fn m -> assert &1 =~ m end))

      is_binary(match) or Regex.regex?(match) ->
        assert_file(file, &assert(&1 =~ match))

      is_function(match, 1) ->
        assert_file(file)
        match.(File.read!(file))

      true ->
        raise inspect({file, match})
    end
  end

  def inject_compilation_error(path) do
    modify_file(path, &Kernel.<>(&1, "boom"))
  end

  def modify_file(path, function) when is_binary(path) and is_function(function, 1) do
    path
    |> File.read!()
    |> function.()
    |> write_file!(path)
  end

  defp write_file!(content, path) do
    File.write!(path, content)
  end

  def revert_to_clean_phoenix_app(app_path) do
    {_, 0} = System.cmd("git", ["restore", "--staged", "."], cd: app_path)
    {_, 0} = System.cmd("git", ["clean", "-df"], cd: app_path)
    {_, 0} = System.cmd("git", ["checkout", "--", "."], cd: app_path)

    :ok
  end

  defp test_apps_path do
    Path.expand("../../test_apps", __DIR__)
  end

  defp project_root_path do
    Path.expand("../../", __DIR__)
  end

  defp generate_new_app(app_name, opts) when is_list(opts) do
    app_path = test_apps_path() |> Path.join(app_name) |> Path.relative_to(project_root_path())

    mix_run!(["phx.new", app_path | opts],
      prompt_responses: :no_to_all,
      cd: project_root_path()
    )
  end

  defp inject_phx_gen_auth_dependency(app_path) do
    file_path = Path.join(app_path, "mix.exs")
    inject = ~s|{:phx_gen_auth, path: "../..", only: [:dev, :test], runtime: false}|

    inject_dependency(file_path, inject)
  end

  defp inject_phx_gen_auth_dependency_in_umbrella(app_path, app_name) do
    file_path = Path.join([app_path, "apps", "#{app_name}_web", "mix.exs"])
    inject = ~s|{:phx_gen_auth, path: "../../../../", only: [:dev, :test], runtime: false}|

    inject_dependency(file_path, inject)
  end

  defp inject_dependency(file_path, dependency) do
    file = File.read!(file_path)

    case Injector.inject_mix_dependency(file, dependency) do
      {:ok, new_file} ->
        File.write!(file_path, new_file)

      :already_injected ->
        :ok
    end
  end

  defp git_init_and_commit(app_path) do
    {_, 0} = System.cmd("git", ["init", "."], cd: app_path)
    {_, 0} = System.cmd("git", ["add", "."], cd: app_path)
    {_, 0} = System.cmd("git", ["config", "user.email", "test@test.com"], cd: app_path)
    {_, 0} = System.cmd("git", ["config", "user.name", "Integration Tester"], cd: app_path)
    {_, 0} = System.cmd("git", ["commit", "-m", "Initial project"], cd: app_path)

    :ok
  end

  defp ecto_drop(app_path), do: mix_run!(["ecto.drop"], cd: app_path)
end
