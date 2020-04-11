defmodule Phx.Gen.Auth.IntegrationTests.DefaultUmbrellaTest do
  use ExUnit.Case, async: true

  import Phx.Gen.Auth.TestSupport.IntegrationTestHelpers

  require Logger

  @moduletag timeout: :infinity
  @moduletag :integration

  setup do
    test_app_path = setup_test_umbrella_app("rainy_day")
    [test_app_path: test_app_path]
  end

  test "new umbrella project with default context and names", %{test_app_path: test_app_path} do
    web_path = Path.join(test_app_path, "apps/rainy_day_web")
    mix_run!(~w(phx.gen.auth Accounts User users), cd: web_path)

    mix_deps_get_and_compile(test_app_path)

    assert_file(Path.join(test_app_path, "apps/rainy_day/test/support/fixtures/accounts_fixtures.ex"))

    assert_file(Path.join(test_app_path, "apps/rainy_day_web/test/support/conn_case.ex"), fn file ->
      assert file =~ "def login_user"
    end)

    assert_no_compilation_warnings(test_app_path)
    assert_mix_test_succeeds(test_app_path)
  end

  test "error messages", %{test_app_path: test_app_path} do
    web_app_path = Path.join(test_app_path, "apps/rainy_day_web")

    assert {output, 1} = mix_run(~w(phx.gen.auth Accounts User users), cd: test_app_path)
    assert output =~ "mix phx.gen.auth can only be run inside an application directory"

    inject_compilation_error(Path.join(test_app_path, "apps/rainy_day/lib/rainy_day/repo.ex"))

    {output, 1} = mix_run(~w(phx.gen.auth Accounts User users), cd: web_app_path)
    assert output =~ "Compilation error in file"

    revert_to_clean_phoenix_app(test_app_path)

    File.rm!(Path.join(test_app_path, "apps/rainy_day/lib/rainy_day/repo.ex"))

    {output, 1} = mix_run(~w(phx.gen.auth Accounts User users), cd: web_app_path)
    assert output =~ "Unable to find RainyDay.Repo"
  end
end
