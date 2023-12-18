defmodule Maxwell.Mixfile do
  use Mix.Project

  @source_url "https://github.com/zhongwencool/maxwell"
  @version "2.4.0-alpha.1"

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
      dialyzer: [plt_add_deps: true],
      elixirc_options: [prune_code_paths: false]
    ]
  end

  def application do
    [extra_applications: extra_applications(Mix.env())]
  end

  defp extra_applications(:test), do: [:ssl, :inets, :logger, :poison, :ibrowse, :hackney]
  defp extra_applications(_), do: [:ssl, :inets, :logger]

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
      {:mime, "~> 1.0 or ~> 2.0"},
      {:poison, "~> 2.1 or ~> 3.0", optional: true},
      {:ibrowse, "~> 4.4", optional: true},
      {:hackney, "~> 1.16", optional: true},
      {:fuse, "~> 2.4", optional: true},
      {:excoveralls, "~> 0.13", only: :test},
      {:inch_ex, "~> 2.0", only: :docs},
      {:credo, "~> 1.5", only: [:dev]},
      {:mimic, "~> 1.3", only: :test},
      {:ex_doc, ">= 0.0.0", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0.0", only: [:dev], runtime: false}
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
