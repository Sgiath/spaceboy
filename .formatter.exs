locals_without_parens = [
  # Spaceboy.Server
  middleware: 1,
  middleware: 2,

  # Spaceboy.Router
  route: 3,
  static: 2,
  static: 3,
  redirect: 2,
  robots: 1
]

[
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib,test}/**/*.{ex,exs}",
    "example/mix.exs",
    "example/{config,lib}/**/*.{ex,exs}"
  ],
  import_deps: [:typed_struct],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
