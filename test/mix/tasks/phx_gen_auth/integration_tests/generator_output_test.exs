defmodule Phx.Gen.Auth.IntegrationTests.GeneratorOutputTest do
  use ExUnit.Case, async: true

  import Phx.Gen.Auth.TestSupport.IntegrationTestHelpers

  require Logger

  @moduletag timeout: :infinity
  @moduletag :integration

  setup_all do
    test_app_path = setup_test_app("generator_output_app")
    [test_app_path: test_app_path]
  end

  setup %{test_app_path: test_app_path} do
    revert_to_clean_phoenix_app(test_app_path)
    :ok
  end

  test "errors on compilation error", %{test_app_path: test_app_path} do
    inject_compilation_error(Path.join(test_app_path, "lib/generator_output_app/repo.ex"))

    {output, 1} = mix_run(~w(phx.gen.auth Accounts User users), cd: test_app_path)
    assert output =~ "Compilation error in file"
  end

  test "errors when missing repo file", %{test_app_path: test_app_path} do
    File.rm!(Path.join(test_app_path, "lib/generator_output_app/repo.ex"))

    {output, 1} = mix_run(~w(phx.gen.auth Accounts User users), cd: test_app_path)
    assert output =~ "Unable to find GeneratorOutputApp.Repo"
  end

  test "errors on invalid config/test.exs", %{test_app_path: test_app_path} do
    modify_file(Path.join(test_app_path, "config/test.exs"), fn _file -> "" end)

    {output, 1} = mix_run(~w(phx.gen.auth Accounts User users), cd: test_app_path)
    assert output =~ "Could not find \"use Mix.Config\" or \"import Config\" in \"config/test.exs\""
  end

  test "prompts the user to add a render call when can't find <body> in app.html.eex",
       %{test_app_path: test_app_path} do
    modify_file(Path.join(test_app_path, "lib/generator_output_app_web/templates/layout/app.html.eex"), fn _file -> "" end)

    output = mix_run!(~w(phx.gen.auth Accounts User users), cd: test_app_path)

    assert output =~ ~s|Add a render call for "_user_menu.html" to lib/generator_output_app_web/templates/layout/app.html.eex|
  end

  test "outputs error when it can't find layout file", %{test_app_path: test_app_path} do
    File.rm!(Path.join(test_app_path, "lib/generator_output_app_web/templates/layout/app.html.eex"))

    output = mix_run!(~w(phx.gen.auth Accounts User users), cd: test_app_path)
    assert output =~ ~r/Unable to find an application layout file to inject.*"_user_menu\.html"/si
  end

  test "outputs error when it can't find conn_case.ex file", %{test_app_path: test_app_path} do
    old_path = Path.join(test_app_path, "test/support/conn_case.ex")
    new_path = Path.join(test_app_path, "test/support/my_conn_case.ex")
    :ok = File.rename(old_path, new_path)

    output = mix_run!(~w(phx.gen.auth Accounts User users), cd: test_app_path)
    assert output =~ ~r/Unable to read file test\/support\/conn_case\.ex/i
  end

  test "outputs error when it can't find router.ex file", %{test_app_path: test_app_path} do
    old_path = Path.join(test_app_path, "lib/generator_output_app_web/router.ex")
    new_path = Path.join(test_app_path, "lib/generator_output_app_web/my_router.ex")
    :ok = File.rename(old_path, new_path)

    output = mix_run!(~w(phx.gen.auth Accounts User users), cd: test_app_path)

    assert output =~ ~r/Unable to read file lib\/generator_output_app_web\/router\.ex/i
    assert output =~ ~s|get "/users/register"|
    assert output =~ ~s|import GeneratorOutputAppWeb.UserAuth|
    assert output =~ ~s|plug :fetch_current_user|
  end
end
