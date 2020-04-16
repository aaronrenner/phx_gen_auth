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

  test "prompts the user to add a render call when can't find <body> in app.html.eex",
       %{test_app_path: test_app_path} do
    modify_file(Path.join(test_app_path, "lib/generator_output_app_web/templates/layout/app.html.eex"), fn _file -> "" end)

    output = mix_run!(~w(phx.gen.auth Accounts User users), cd: test_app_path)

    assert output =~ ~s|Add a render call for "_user_menu.html" to lib/generator_output_app_web/templates/layout/app.html.eex|
  end
end
