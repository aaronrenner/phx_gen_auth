defmodule Mix.Phx.Gen.Auth.InjectorTest do
  use ExUnit.Case, async: true

  alias Mix.Phx.Gen.Auth.Injector

  test "inject_mix_dependency/2 injects before existing dependencies" do
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

  test "inject_mix_dependency/2 when injected dependency already exists" do
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

  test "inject_mix_dependency/2 when unable to automatically inject" do
    existing_file = """
    defmodule MyApp.MixFile do
    end
    """

    inject = ~s|{:bcrypt_elixir, "~> 2.0"}|

    assert {:error, :unable_to_inject} = Injector.inject_mix_dependency(existing_file, inject)
  end

  test "inject_before_final_end/2 injects code when not previously injected" do
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

  test "inject_before_final_end/2 returns :already_injected when code has been injected" do
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
