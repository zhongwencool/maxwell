defmodule Maxwell.Mixfile do
  use Mix.Project

  @source_url "https://github.com/zhongwencool/maxwell"
  @version "2.3.0"

  def project do
    [
      app: :maxwell,
      version: @version,
      elixir: "~> 1.8",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: "Maxwell is an HTTP client adapter.",
      docs: docs(),
      package: package(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      xref: [exclude: [Poison, Maxwell.Adapter.Ibrowse]],
      dialyzer: [plt_add_deps: true]
    ]
  end

  def application do
    [applications: applications(Mix.env())]
  end

  defp applications(:test), do: [:logger, :poison, :ibrowse, :hackney]
  defp applications(_), do: [:logger]

  defp package do
    [
      maintainers: ["zhongwencool"],
      links: %{
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md",
        "GitHub" => @source_url
      },
      files: ~w(lib LICENSE mix.exs README.md CHANGELOG.md .formatter.exs),
      licenses: ["MIT"]
    ]
  end

  defp deps do
    [
      {:mimerl, "~> 1.0.2"},
      {:poison, "~> 2.1 or ~> 3.0", optional: true},
      {:ibrowse, "~> 4.4", optional: true},
      {:hackney, "~> 1.15", optional: true},
      {:fuse, "~> 2.4", optional: true},
      {:excoveralls, "~> 0.6", only: :test},
      {:inch_ex, "~> 2.0", only: :docs},
      {:credo, "~> 1.1", only: [:dev]},
      {:mimic, "~> 1.1", only: :test},
      {:ex_doc, ">= 0.0.0", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: @version,
      extras: [
        "README.md",
        "CHANGELOG.md"
      ]
    ]
  end
end
