defmodule ArchiveBundle.Mixfile do
  use Mix.Project

  def project do
    [app: :archive_bundle,
     version: "1.0.0",
     elixir: "~> 1.2",
     deps: deps(),
     preferred_cli_env: ["archive.bundle": :prod]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :crypto]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    []
  end
end
