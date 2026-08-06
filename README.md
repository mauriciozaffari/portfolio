# zaffari.casa

Personal portfolio and professional showcase site for Mauricio Zaffari.

Rails 8 + Hotwire, server-rendered, with all content authored as Markdown in
[`data/`](data/). There is no database: the app reads content from the
repository and stores nothing, which keeps deployment to one stateless
container. See [AGENTS.md](AGENTS.md) for the rules that follow from that, and
[features/TODO.md](features/TODO.md) for what is built and what is planned.

## Requirements

Ruby, pinned in [`.tool-versions`](.tool-versions). No Node toolchain — Tailwind
runs from the binary vendored by the `tailwindcss-ruby` gem.

## Setup

```sh
bin/setup --skip-server
```

## Run

```sh
bin/dev
```

Starts the server on port 3000 alongside the Tailwind watcher.

## Quality gate

```sh
bin/ci
```

One entry point for humans and CI: RuboCop, ERB and HTML analysis, an importmap
vulnerability audit, and the RSpec suite. Exits non-zero if any step fails.
Individual steps are `bin/rubocop`, `bin/herb analyze app/views`,
`bin/importmap audit`, and `bin/rspec`.
