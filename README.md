# mauricio.zaffari.casa

Personal portfolio and professional showcase site for Mauricio Zaffari.

Rails 8, server-rendered, with all content authored as Markdown in
[`data/`](data/). There is no database: the app reads content from the
repository and stores nothing, which keeps deployment to one stateless
container. The page ships no JavaScript either — the Hotwire gems are installed
and nothing is pinned, for the reason measured in
[features/landing-page/IMPLEMENTATION.md](features/landing-page/IMPLEMENTATION.md).
See [AGENTS.md](AGENTS.md) for the rules that follow from all of that,
[DESIGN.md](DESIGN.md) for the visual language every UI change is held to, and
[features/TODO.md](features/TODO.md) for what is built and what is planned.

## Requirements

Ruby, pinned in [`.tool-versions`](.tool-versions). There is no Node toolchain:
no `package.json`, no bundler, and Tailwind runs from the binary vendored by the
`tailwindcss-ruby` gem. `.tool-versions` also pins `nodejs`, which nothing in
the build reads — removing it is a pending cleanup tracked in
[features/TODO.md](features/TODO.md).

## Setup

```sh
bin/setup --skip-server
```

## Run

```sh
bin/dev
```

Starts the server alongside the Tailwind watcher, on port 3000 unless `PORT`
says otherwise — see [`.env.example`](.env.example).

## Quality gate

```sh
bin/ci
```

One entry point for humans and CI, and it exits non-zero if any step fails:

- `bin/setup --skip-server` — dependencies, so a green run means green from
  scratch.
- `bin/rubocop` — Ruby style.
- `bin/herb analyze app/views` — ERB and HTML analysis.
- `bin/rails content:validate` — every record in `data/` against the
  front-matter schema.
- `bin/rails content:scan` — the publication policy over `data/`. Compensation,
  contact details outside the approved allowlist, credentials and identifiers
  all fail the build here rather than in review.
- `bin/rails content:paths` — proves no file under `app/`, `lib/` or `config/`
  names a filesystem path outside the application root, so the private source
  material the records are curated from can never be read at runtime.
- `bin/importmap audit` and `bin/bundle-audit check` — vulnerability audits for
  pinned JavaScript and for the gems in the image.
- `bin/rspec` — the suite.

The three `content:` steps are why a public repository is safe to push: each
fails for a different reason, and each is itself proven to fail by a spec.
