defmodule Phx.Gen.Auth.MixProject do
  use Mix.Project

  def project do
    [
      app: :phx_gen_auth,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      "test.integration": [
        "test.integration.no_cleanup",
        "cmd 'mix test.integration.reset'"
      ],
      "test.integration.no_cleanup": [
        "test.integration.reset",
        "test.integration.setup",
        "test.integration.run"
      ],
      "test.integration.reset": [
        "cmd 'cd test_apps/demo && git restore . && git clean -d -f && MIX_ENV=test mix ecto.drop'"
      ],
      "test.integration.setup": [
        "cmd 'cd test_apps/demo && mix compile --force --warnings-as-errors && mix phx.gen.auth Accounts User users'"
      ],
      "test.integration.run": [
        "cmd 'cd test_apps/demo && mix test'"
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, github: "phoenixframework/phoenix"}
    ]
  end
end
