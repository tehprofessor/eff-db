defmodule EffDB.MixProject do
  use Mix.Project

  def project do
    [
      app: :eff_db,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EffDB.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:argon2_elixir, "~> 2.0"},
      {:elixir_uuid, "~> 1.2"},
      {:fdb, "6.1.8-0"},
      {:faker, "~> 0.1", only: [:dev]},
    ]
  end
end
