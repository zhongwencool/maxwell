[
  inputs: [
    ".formatter.exs",
    "mix.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  locals_without_parens: [
    adapter: 1,
    middleware: 1,
    middleware: 2
  ],
  export: [
    locals_without_parens: [
      adapter: 1,
      middleware: 1,
      middleware: 2
    ]
  ]
]
