defmodule Matryoshka.MixProject do
  use Mix.Project

  def project do
    [
      app: :matryoshka,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ssh]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp description() do
    "Matryoshka provides composable storage functionality through stores and
    storage combinators. Any module that implements the Storage protocol (get,
    fetch, put, delete) is a store. Some stores compute their storage call
    results on top of other stores. These are known as storage combinators.
    Complex storage requirements can thus be met by composing together many
    storage combinators into one store."
  end

  defp package() do
    [
      name: "matryoshka",
      maintainers: ["Julian Ferrone"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/julianferrone/matryoshka"}
    ]
  end
end
