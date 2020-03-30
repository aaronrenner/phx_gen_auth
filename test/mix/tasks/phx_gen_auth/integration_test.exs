Code.require_file("../../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Phx.Gen.Auth.IntegrationTest do
  use ExUnit.Case

  alias Mix.Tasks.Phx.New

  @moduletag timeout: :infinity
  @moduletag :integration

  test "single project with default schema and context names" do
    in_test_app("demo", fn ->
      mix_run!(["phx.gen.auth", "Accounts", "User", "users"])
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

  defp in_test_app(app_name, opts \\ [], function) when is_list(opts) when is_function(function, 0) do
    in_test_apps(fn ->
      test_app_path = Path.join(test_apps_path(), app_name)

      delete_old_app(test_app_path)

      generate_new_app(app_name, opts)

      File.cd!(test_app_path, fn ->
        inject_phx_gen_auth_dependency()
        mix_deps_get_and_compile()
        ecto_drop()
        git_init_and_commit()
        function.()
      end)
    end)
  end

  defp in_test_apps(function) do
    path = test_apps_path()
    File.mkdir_p!(path)
    File.cd!(path, function)
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
