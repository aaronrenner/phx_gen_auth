defmodule Phx.Gen.Auth.MixProject do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :phx_gen_auth,
      version: @version,
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [docs: :docs],
      description: "An authentication system generator for Phoenix 1.5+",
      docs: docs(),
      deps: deps(),
      package: package()
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
      {:phoenix, "~> 1.5.2"},
      {:phx_new, "~> 1.5.2", only: [:dev, :test]},
      # Docs dependencies
      {:ex_doc, "~> 0.20", only: :docs}
    ]
  end

  defp docs do
    [
      main: "overview",
      source_ref: "v#{@version}",
      source_url: "https://github.com/aaronrenner/phx_gen_auth",
      extras: extras()
    ]
  end

  defp extras do
    ["guides/overview.md"]
  end

  defp package do
    [
      maintainers: ["Aaron Renner", "José Valim"],
      licenses: ["Apache 2"],
      links: %{"GitHub" => "https://github.com/aaronrenner/phx_gen_auth"}
    ]
  end
end
