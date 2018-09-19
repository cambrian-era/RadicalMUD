defmodule MUD.MixProject do
  use Mix.Project

  def project do
    [
      app: :mud,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MUD, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:elixir_uuid, "~> 1.2"},
      {:power_assert, "~>0.1.2", only: :test}
    ]
  end
end
