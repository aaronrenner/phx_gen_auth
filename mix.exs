defmodule Phx.Gen.Auth.MixProject do
  use Mix.Project

  @version "0.1.0-alpha.0"

  def project do
    [
      app: :phx_gen_auth,
      version: "0.1.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [docs: :docs],
      docs: docs(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.5.0-rc.0"},
      {:phx_new, "~> 1.5.0-rc.0", only: [:dev, :test]},
      # Docs dependencies
      {:ex_doc, "~> 0.20", only: :docs}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}"
    ]
  end
end
