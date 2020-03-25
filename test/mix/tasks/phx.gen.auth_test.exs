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

      assert_file("lib/phx_gen_auth/accounts/user.ex", fn file ->
        assert file =~ "defmodule PhxGenAuth.Accounts.User"
        assert file =~ ~s|schema "users"|
      end)

      assert_file("lib/phx_gen_auth/accounts/user_token.ex", fn file ->
        assert file =~ "defmodule PhxGenAuth.Accounts.UserToken"
        assert file =~ ~s|schema "user_tokens"|
      end)

      assert_file("lib/phx_gen_auth_web/views/user_confirmation_view.ex", fn file ->
        assert file =~ "defmodule PhxGenAuthWeb.UserConfirmationView"
      end)

      assert_file("lib/phx_gen_auth_web/views/user_registration_view.ex", fn file ->
        assert file =~ "defmodule PhxGenAuthWeb.UserRegistrationView"
      end)

      assert_file("lib/phx_gen_auth_web/views/user_reset_password_view.ex", fn file ->
        assert file =~ "defmodule PhxGenAuthWeb.UserResetPasswordView"
      end)

      assert_file("lib/phx_gen_auth_web/views/user_session_view.ex", fn file ->
        assert file =~ "defmodule PhxGenAuthWeb.UserSessionView"
      end)

      assert_file("lib/phx_gen_auth_web/views/user_settings_view.ex", fn file ->
        assert file =~ "defmodule PhxGenAuthWeb.UserSettingsView"
      end)
    end)
  end
end
