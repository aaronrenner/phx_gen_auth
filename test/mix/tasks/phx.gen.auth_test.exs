Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Phx.Gen.AuthTest do
  use ExUnit.Case

  import MixHelper
  alias Mix.Tasks.Phx.Gen

  setup do
    Mix.Task.clear()
    :ok
  end

  defp in_tmp_auth_project(test, func) do
    in_tmp_project(test, fn ->
      File.mkdir_p!("config")
      File.mkdir_p!("lib/phx_gen_auth_web")
      File.mkdir_p!("lib/phx_gen_auth_web/templates/layout")
      File.mkdir_p!("test/support")
      File.touch!("test/support/conn_case.ex")
      File.write!("mix.exs", mixfile_contents())
      File.write!("lib/phx_gen_auth_web/router.ex", routerfile_contents())
      File.write!("lib/phx_gen_auth_web/templates/layout/app.html.eex", app_layout_contents())

      func.()
    end)
  end

  defp in_tmp_auth_umbrella_project(test, func) do
    in_tmp_umbrella_project(test, fn ->
      File.mkdir_p!("../config")
      File.mkdir_p!("phx_gen_auth/lib/phx_gen_auth")
      File.mkdir_p!("phx_gen_auth_web/lib/phx_gen_auth_web")
      File.mkdir_p!("phx_gen_auth_web/test/support")
      File.write!("phx_gen_auth/mix.exs", mixfile_contents())
      File.touch!("phx_gen_auth_web/test/support/conn_case.ex")
      File.write!("phx_gen_auth_web/lib/phx_gen_auth_web/router.ex", routerfile_contents())

      func.()
    end)
  end

  test "generates auth logic", config do
    in_tmp_auth_project(config.test, fn ->
      Gen.Auth.run(~w(Accounts User users))

      assert_file("mix.exs", fn file ->
        assert file =~ ~s|{:bcrypt_elixir, "~> 2.0"}|
      end)

      assert_file("config/test.exs", fn file ->
        assert file =~ "config :bcrypt_elixir, :log_rounds, 1"
      end)

      assert_file("lib/phx_gen_auth/accounts.ex")
      assert_file("lib/phx_gen_auth/accounts/user_notifier.ex")
      assert_file("lib/phx_gen_auth/accounts/user.ex")
      assert_file("lib/phx_gen_auth/accounts/user_token.ex")

      assert [migration] = Path.wildcard("priv/repo/migrations/*_create_user_auth_tables.exs")

      assert_file(migration, fn file ->
        assert file =~ "create table(:users) do"
        assert file =~ "create table(:user_tokens) do"
      end)

      assert_file("test/phx_gen_auth/accounts_test.exs")

      assert_file("lib/phx_gen_auth_web/controllers/user_auth.ex")
      assert_file("lib/phx_gen_auth_web/controllers/user_confirmation_controller.ex")
      assert_file("lib/phx_gen_auth_web/controllers/user_registration_controller.ex")
      assert_file("lib/phx_gen_auth_web/controllers/user_reset_password_controller.ex")
      assert_file("lib/phx_gen_auth_web/controllers/user_session_controller.ex")
      assert_file("lib/phx_gen_auth_web/controllers/user_settings_controller.ex")

      assert_file("lib/phx_gen_auth_web/router.ex", fn file ->
        assert file =~ "import PhxGenAuthWeb.UserAuth"
        assert file =~ "plug :fetch_current_user"
        assert file =~ ~s|delete "/users/logout", UserSessionController, :delete|
      end)

      assert_file("lib/phx_gen_auth_web/templates/layout/_user_menu.html.eex")
      assert_file("lib/phx_gen_auth_web/templates/user_confirmation/new.html.eex")
      assert_file("lib/phx_gen_auth_web/templates/user_registration/new.html.eex")
      assert_file("lib/phx_gen_auth_web/templates/user_reset_password/new.html.eex")
      assert_file("lib/phx_gen_auth_web/templates/user_reset_password/edit.html.eex")
      assert_file("lib/phx_gen_auth_web/templates/user_session/new.html.eex")
      assert_file("lib/phx_gen_auth_web/templates/user_settings/edit.html.eex")

      assert_file("lib/phx_gen_auth_web/templates/layout/app.html.eex", fn file ->
        assert file =~ ~s|<%= render "_user_menu.html", assigns %>|
      end)

      assert_file("lib/phx_gen_auth_web/views/user_confirmation_view.ex")
      assert_file("lib/phx_gen_auth_web/views/user_registration_view.ex")
      assert_file("lib/phx_gen_auth_web/views/user_reset_password_view.ex")
      assert_file("lib/phx_gen_auth_web/views/user_session_view.ex")
      assert_file("lib/phx_gen_auth_web/views/user_settings_view.ex")

      assert_file("test/phx_gen_auth_web/controllers/user_confirmation_controller_test.exs")
      assert_file("test/phx_gen_auth_web/controllers/user_reset_password_controller_test.exs")
      assert_file("test/phx_gen_auth_web/controllers/user_registration_controller_test.exs")
      assert_file("test/phx_gen_auth_web/controllers/user_session_controller_test.exs")
      assert_file("test/phx_gen_auth_web/controllers/user_settings_controller_test.exs")

      assert_file("test/phx_gen_auth_web/controllers/user_auth_test.exs", fn file ->
        assert file =~ "PhxGenAuthWeb.Endpoint.config("
      end)

      assert_file("test/support/conn_case.ex", fn file ->
        assert file =~ "def register_and_login_user"
        assert file =~ "def login_user"
      end)

      assert_file("test/support/fixtures/accounts_fixtures.ex")
    end)
  end

  # TODO Figure out how to get these umbrella tests working
  @tag :skip
  test "in umbrella app", config do
    in_tmp_auth_umbrella_project(config.test, fn ->
      File.cd!("phx_gen_auth_web")

      # Mix.Project.in_project(:phx_gen_auth_web, ".", fn _module ->
      Gen.Auth.run(~w(Accounts User users))

      # end)

      assert_file("../phx_gen_auth/mix.exs", fn file ->
        assert file =~ ~s|{:bcrypt_elixir, "~> 2.0"}|
      end)

      assert_file("../config/test.exs", fn file ->
        assert file =~ "config :bcrypt_elixir, :log_rounds, 1"
      end)

      assert [migration] = Path.wildcard("phx_gen_auth/priv/repo/migrations/*_create_user_auth_tables.exs")

      assert_file(migration, fn file ->
        assert file =~ "create table(:users) do"
        assert file =~ "create table(:user_tokens) do"
      end)

      assert_file("lib/phx_gen_auth_web/router.ex", fn file ->
        assert file =~ "import PhxGenAuthWeb.UserAuth"
        assert file =~ "plug :fetch_current_user"
        assert file =~ ~s|delete "/users/logout", UserSessionController, :delete|
      end)

      assert_file("phoenix_gen_auth/test/support/conn_case.ex", fn file ->
        assert file =~ "def register_and_login_user"
        assert file =~ "def login_user"
      end)
    end)
  end

  # test "does not inject code if its already been injected"

  defp routerfile_contents do
    """
    defmodule PhxGenAuthWeb.Router do
      use PhxGenAuthWeb, :router

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_flash
        plug :protect_from_forgery
        plug :put_secure_browser_headers
      end

      pipeline :api do
        plug :accepts, ["json"]
      end

      scope "/", PhxGenAuthWeb do
        pipe_through :browser

        get "/", PageController, :index
      end

      # Other scopes may use custom stacks.
      # scope "/api", DemoWeb do
      #   pipe_through :api
      # end
    end
    """
  end

  defp app_layout_contents do
    """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>Demo · Phoenix Framework</title>
        <link rel="stylesheet" href="<%= Routes.static_path(@conn, "/css/app.css") %>"/>
        <%= csrf_meta_tag() %>
        <script defer type="text/javascript" src="<%= Routes.static_path(@conn, "/js/app.js") %>"></script>
      </head>
      <body>
        <header>
          <section class="container">
            <nav role="navigation">
              <ul>
                <li><a href="https://hexdocs.pm/phoenix/overview.html">Get Started</a></li>
              </ul>
            </nav>
            <a href="https://phoenixframework.org/" class="phx-logo">
              <img src="<%= Routes.static_path(@conn, "/images/phoenix.png") %>" alt="Phoenix Framework Logo"/>
            </a>
          </section>
        </header>
        <main role="main" class="container">
          <p class="alert alert-info" role="alert"><%= get_flash(@conn, :info) %></p>
          <p class="alert alert-danger" role="alert"><%= get_flash(@conn, :error) %></p>
          <%= @inner_content %>
        </main>
      </body>
    </html>
    """
  end

  defp mixfile_contents do
    """
      # Specifies your project dependencies.
      #
      # Type `mix help deps` for examples and options.
      defp deps do
        [
          {:phoenix, github: "phoenixframework/phoenix", override: true},
          {:phx_gen_auth, path: "../..", only: [:dev, :test], runtime: false},
          {:phoenix_ecto, "~> 4.1"},
          {:ecto_sql, "~> 3.4"},
          {:postgrex, ">= 0.0.0"},
          {:phoenix_html, "~> 2.11"},
          {:phoenix_live_reload, "~> 1.2", only: :dev},
          {:telemetry_metrics, "~> 0.4"},
          {:telemetry_poller, "~> 0.4"},
          {:gettext, "~> 0.11"},
          {:jason, "~> 1.0"},
          {:plug_cowboy, "~> 2.0"}
        ]
      end
    """
  end
end
