defmodule Subaru.MixProject do
  use Mix.Project

  def project do
    [
      app: :subaru,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Subaru.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:velocy, "~> 0.1"},
      {:arangox, git: "https://github.com/ArangoDB-Community/arangox"}
    ]
  end
end
