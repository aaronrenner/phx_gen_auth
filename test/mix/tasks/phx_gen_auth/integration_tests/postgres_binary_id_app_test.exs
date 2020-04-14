defmodule Phx.Gen.Auth.IntegrationTests.PostgresBinaryIdAppTest do
  use ExUnit.Case, async: true

  import Phx.Gen.Auth.TestSupport.IntegrationTestHelpers

  require Logger

  @moduletag timeout: :infinity
  @moduletag :integration

  setup do
    test_app_path = setup_test_app("postgres_binary_id", ~w(--binary-id))
    [test_app_path: test_app_path]
  end

  test "generates models with binary ids", %{test_app_path: test_app_path} do
    mix_run!(~w(phx.gen.auth Accounts User users), cd: test_app_path)

    [migration] =
      test_app_path
      |> Path.join("priv/repo/migrations/*_create_user_auth_tables.exs")
      |> Path.wildcard()

    assert_file(migration, fn file ->
      assert file =~ "create table(:users, primary_key: false)"
      assert file =~ "create table(:user_tokens, primary_key: false)"
      assert file =~ "add :id, :binary_id, primary_key: true"
    end)

    mix_deps_get_and_compile(test_app_path)

    assert_no_compilation_warnings(test_app_path)
    assert_mix_test_succeeds(test_app_path)
  end
end
