Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Phx.Gen.AuthTest do
  use ExUnit.Case

  import MixHelper
  alias Mix.Tasks.Phx.Gen

  setup do
    Mix.Task.clear()
    :ok
  end

  test "generates auth logic", config do
    in_tmp_project(config.test, fn ->
      Gen.Auth.run(~w(Accounts User users))

      assert_file("lib/phx_gen_auth/accounts/user_notifier.ex", fn file ->
        assert file =~ "defmodule PhxGenAuth.Accounts.UserNotifier"
        assert file =~ "def deliver_confirmation_instructions(user, url)"
      end)
    end)
  end
end
