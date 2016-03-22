defmodule Maxwell.Mixfile do
  use Mix.Project

  def project do
    [app: :maxwell,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :ibrowse, :poison]]
  end

  defp deps do
    [{:tesla, github: "zhongwencool/tesla", branch: "master"},
     {:ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.2", optional: true},
     {:poison, github: "devinus/poison", tag: "2.1.0", optional: true}
    ]
  end

end
