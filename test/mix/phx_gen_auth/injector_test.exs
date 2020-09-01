defmodule Mix.Phx.Gen.Auth.InjectorTest do
  use ExUnit.Case, async: true

  alias Mix.Phx.Gen.Auth.Injector

  describe "inject_mix_dependency/2" do
    test "injects before existing dependencies" do
      existing_file = """
      defmodule RainyDay.MixProject do
        use Mix.Project

        def project do
          [
            app: :rainy_day,
            version: "0.1.0",
            build_path: "../../_build",
            config_path: "../../config/config.exs",
            deps_path: "../../deps",
            lockfile: "../../mix.lock",
            elixir: "~> 1.7",
            elixirc_paths: elixirc_paths(Mix.env()),
            start_permanent: Mix.env() == :prod,
            aliases: aliases(),
            deps: deps()
          ]
        end

        # Configuration for the OTP application.
        #
        # Type `mix help compile.app` for more information.
        def application do
          [
            mod: {RainyDay.Application, []},
            extra_applications: [:logger, :runtime_tools]
          ]
        end

        # Specifies which paths to compile per environment.
        defp elixirc_paths(:test), do: ["lib", "test/support"]
        defp elixirc_paths(_), do: ["lib"]

        # Specifies your project dependencies.
        #
        # Type `mix help deps` for examples and options.
        defp deps do
          [
            {:phoenix_pubsub, "~> 2.0-dev", github: "phoenixframework/phoenix_pubsub"},
            {:ecto_sql, "~> 3.4"},
            {:postgrex, ">= 0.0.0"},
            {:jason, "~> 1.0"}
          ]
        end

        # Aliases are shortcuts or tasks specific to the current project.
        # For example, to create, migrate and run the seeds file at once:
        #
        #     $ mix ecto.setup
        #
        # See the documentation for `Mix` for more info on aliases.
        defp aliases do
          [
            "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
            "ecto.reset": ["ecto.drop", "ecto.setup"],
            test: ["ecto.create --quiet", "ecto.migrate", "test"]
          ]
        end
      end
      """

      inject = ~s|{:bcrypt_elixir, "~> 2.0"}|

      assert {:ok, new_file} = Injector.inject_mix_dependency(existing_file, inject)

      assert new_file == """
             defmodule RainyDay.MixProject do
               use Mix.Project

               def project do
                 [
                   app: :rainy_day,
                   version: "0.1.0",
                   build_path: "../../_build",
                   config_path: "../../config/config.exs",
                   deps_path: "../../deps",
                   lockfile: "../../mix.lock",
                   elixir: "~> 1.7",
                   elixirc_paths: elixirc_paths(Mix.env()),
                   start_permanent: Mix.env() == :prod,
                   aliases: aliases(),
                   deps: deps()
                 ]
               end

               # Configuration for the OTP application.
               #
               # Type `mix help compile.app` for more information.
               def application do
                 [
                   mod: {RainyDay.Application, []},
                   extra_applications: [:logger, :runtime_tools]
                 ]
               end

               # Specifies which paths to compile per environment.
               defp elixirc_paths(:test), do: ["lib", "test/support"]
               defp elixirc_paths(_), do: ["lib"]

               # Specifies your project dependencies.
               #
               # Type `mix help deps` for examples and options.
               defp deps do
                 [
                   {:bcrypt_elixir, "~> 2.0"},
                   {:phoenix_pubsub, "~> 2.0-dev", github: "phoenixframework/phoenix_pubsub"},
                   {:ecto_sql, "~> 3.4"},
                   {:postgrex, ">= 0.0.0"},
                   {:jason, "~> 1.0"}
                 ]
               end

               # Aliases are shortcuts or tasks specific to the current project.
               # For example, to create, migrate and run the seeds file at once:
               #
               #     $ mix ecto.setup
               #
               # See the documentation for `Mix` for more info on aliases.
               defp aliases do
                 [
                   "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
                   "ecto.reset": ["ecto.drop", "ecto.setup"],
                   test: ["ecto.create --quiet", "ecto.migrate", "test"]
                 ]
               end
             end
             """
    end

    test "when injected dependency already exists" do
      existing_file = """
      defmodule MyApp.MixFile do
        defp deps do
          [
            {:bcrypt_elixir, "~> 2.0"},
            {:ecto_sql, "~> 2.0"}
          ]
        end
      end
      """

      inject = ~s|{:bcrypt_elixir, "~> 2.0"}|

      assert :already_injected = Injector.inject_mix_dependency(existing_file, inject)
    end

    test "when unable to automatically inject" do
      existing_file = """
      defmodule MyApp.MixFile do
      end
      """

      inject = ~s|{:bcrypt_elixir, "~> 2.0"}|

      assert {:error, :unable_to_inject} = Injector.inject_mix_dependency(existing_file, inject)
    end
  end

  describe "inject_before_final_end/2" do
    test "injects code when not previously injected" do
      existing_code = """
      defmodule MyApp.Router do
        use MyApp, :router
      end
      """

      code_to_inject = """

        scope "/", MyApp do
          resources "/companies", CompanyController
        end
      """

      assert {:ok, new_code} = Injector.inject_before_final_end(existing_code, code_to_inject)

      assert new_code == """
             defmodule MyApp.Router do
               use MyApp, :router

               scope "/", MyApp do
                 resources "/companies", CompanyController
               end
             end
             """
    end

    test "returns :already_injected when code has been injected" do
      existing_code = """
      defmodule MyApp.Router do
        use MyApp, :router

        scope "/", MyApp do
          resources "/companies", CompanyController
        end
      end
      """

      code_to_inject = """

        scope "/", MyApp do
          resources "/companies", CompanyController
        end
      """

      assert :already_injected = Injector.inject_before_final_end(existing_code, code_to_inject)
    end
  end

  describe "inject_unless_contains/3" do
    test "injects when code doesn't already contain code_to_inject" do
      existing_code = """
      <html>
        <body>
          <h1>My App</h1>
        </body>
      </html>
      """

      code_to_inject = ~s|<%= render "_user_menu.html" %>|

      assert {:ok, new_code} =
               Injector.inject_unless_contains(
                 existing_code,
                 code_to_inject,
                 &String.replace(&1, "<body>", "<body>\n    #{&2}")
               )

      assert new_code == """
             <html>
               <body>
                 <%= render "_user_menu.html" %>
                 <h1>My App</h1>
               </body>
             </html>
             """
    end

    test "returns :already_injected when the existing code already contains code_to_inject" do
      existing_code = """
      <html>
        <body>
          <nav role="navigation">
            <%= render "_user_menu.html" %>
          </nav>
          <h1>My App</h1>
        </body>
      </html>
      """

      code_to_inject = ~s|<%= render "_user_menu.html" %>|

      assert :already_injected =
               Injector.inject_unless_contains(
                 existing_code,
                 code_to_inject,
                 &String.replace(&1, "<body>", "<body>\n    #{&2}")
               )
    end

    test "returns {:error, :unable_to_inject} when no change is made" do
      existing_code = ""

      code_to_inject = ~s|<%= render "_user_menu.html" %>|

      assert {:error, :unable_to_inject} =
               Injector.inject_unless_contains(
                 existing_code,
                 code_to_inject,
                 &String.replace(&1, "<body>", "<body>\n    #{&2}")
               )
    end
  end
end
