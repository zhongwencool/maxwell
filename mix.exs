defmodule Maxwell.Mixfile do
  use Mix.Project

  def project do
    [app: :maxwell,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     deps: deps]
  end

  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :poison,]]
  end

  defp deps do
    [
     {:mimerl, "~> 1.0.2"}, # for find multipart ctype
     {:ibrowse, "~> 4.2", optional: true, only: :test},
     {:poison, "~> 2.1", optional: true, only: :test},
     {:hackney, "~> 1.6", optional: true, only: :test},
     {:excoveralls, "~> 0.5.1", only: :test},
    ]
  end

end
