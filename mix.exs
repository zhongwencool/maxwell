defmodule Maxwell.Mixfile do
  use Mix.Project

  def project do
    [app: :maxwell,
     version: "2.2.2",
     elixir: "~> 1.8",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: [
       maintainers: ["zhongwencool"],
       links: %{"GitHub" => "https://github.com/zhongwencool/maxwell"},
       files: ~w(lib LICENSE mix.exs README.md),
       description: """
       Maxwell is an HTTP client adapter.
       """,
       licenses: ["MIT"]
     ],
     test_coverage: [tool: ExCoveralls],
     xref: [exclude: [Poison, Maxwell.Adapter.Ibrowse]],
     dialyzer: [plt_add_deps: true],
     deps: deps()]
  end

  # Type "mix help compile.app" for more information
  def application do
    [applications: applications(Mix.env)]
  end

  defp applications(:test), do: [:logger, :poison, :ibrowse, :hackney]
  defp applications(_), do: [:logger]

  defp deps do
    [
      {:mimerl, "~> 1.0.2"}, # for find multipart ctype
      {:poison, "~> 2.1 or ~> 3.0", optional: true},
      {:ibrowse, "~> 4.4", optional: true},
      {:hackney, "~> 1.15", optional: true},
      {:fuse, "~> 2.4", optional: true},
      {:excoveralls, "~> 0.6", only: :test},
      {:ex_doc, "~> 0.15", only: [:dev]},
      {:inch_ex, "~> 2.0", only: :docs},
      {:credo, "~> 1.1", only: [:dev]},
      {:mimic, "~> 1.1", only: :test},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false}
    ]
  end

end
