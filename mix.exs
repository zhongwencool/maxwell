defmodule Maxwell.Mixfile do
  use Mix.Project

  def project do
    [app: :maxwell,
     version: "1.0.2",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: [
       maintainers: ["zhongwencool"],
       links: %{"GitHub" => "https://github.com/zhongwencool/maxwell"},
       files: ~w(lib LICENSE mix.exs README.md),
       description: """
       Maxwell is an HTTP client that provides a common interface over many adapters (such as hackney, ibrowse) and embraces the concept of Rack middleware when processing the request/response cycle.
       """,
       licenses: ["MIT"]
     ],
     test_coverage: [tool: ExCoveralls],
     xref: [exclude: [Poison, Maxwell.Adapter.Ibrowse]],
     deps: deps]
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
      {:poison, "~> 2.1", optional: true},
      {:ibrowse, "~> 4.2", optional: true},
      {:hackney, "~> 1.6", optional: true},
      {:excoveralls, "~> 0.5.1", only: :test},
      {:ex_doc, ">= 0.11.4", only: [:dev]},
      {:markdown, github: "devinus/markdown", only: [:dev]},
      {:cmark, "~> 0.6", only: [:dev]}
    ]
  end

end

