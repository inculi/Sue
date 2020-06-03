defmodule Sue.MixProject do
  use Mix.Project

  def project do
    [
      app: :sue,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Sue.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_gram, path: "/Users/robert/prog.nosync/ex_gram"},
      {:tesla, "~> 1.3.3"},
      {:jason, "~> 1.2"},
      {:castore, "~> 0.1.0"},
      {:mint, "~> 1.1"},
      {:sqlitex, "~> 1.7"}
    ]
  end
end
