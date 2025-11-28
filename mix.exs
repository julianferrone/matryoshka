defmodule Matryoshka.MixProject do
  use Mix.Project

  def project do
    [
      app: :matryoshka,
      version: "0.1.0",
      elixir: "~> 1.15",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Matryoshka",
      source_url: "https://github.com/julianferrone/matryoshka"
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
      {:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true}
    ]
  end

  defp description() do
    "Matryoshka provides composable storage functionality through stores and
    storage combinators."
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
