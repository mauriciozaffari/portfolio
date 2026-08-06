# syntax=docker/dockerfile:1
# check=error=true

# The production image: one stateless container, which is the whole point of
# this application having no database. See features/deployment/SPEC.md.
#
# Build and run it locally with:
#   docker build -t portfolio .
#   docker run --rm -p 8080:3000 -e RAILS_MASTER_KEY=<config/master.key> portfolio
#
# Deploys are done by Kamal (config/deploy.yml), which builds this same file.

# Kept in step with .tool-versions by hand; there is no Node toolchain here to
# read it for us. The Debian codename is pinned too, so that a new `slim` base
# cannot change the runtime out from under a rebuild of an old commit.
ARG RUBY_VERSION=4.0.6
FROM docker.io/library/ruby:${RUBY_VERSION}-slim-trixie AS base

WORKDIR /rails

# Runtime packages only. No database client, no libvips, no Node: this app
# renders Markdown and serves one stylesheet.
#   curl        - lets `docker exec` reach /up when a deploy is misbehaving
#   libjemalloc2 - materially lower RSS for a long-running Ruby process, which
#                  is what a small VPS is short of
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development test" \
    LD_PRELOAD="libjemalloc.so.2" \
    MALLOC_ARENA_MAX="2"


# Build stage. Nothing from here reaches the final image except the installed
# gems and the compiled assets.
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Gems first, so that a content or view edit does not invalidate the layer.
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

RUN bundle exec bootsnap precompile app/ lib/

# Assets are compiled here, at build time, never at boot. tailwindcss-rails
# hooks `tailwindcss:build` onto this task, which is why no Node runs.
#
# SECRET_KEY_BASE_DUMMY makes the app bootable for the length of this command
# without a real key. RAILS_MASTER_KEY is never present during the build, so it
# cannot end up in a layer.
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile && \
    bundle exec bootsnap precompile app/ lib/


# Final image.
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run as a non-root user. Only the two paths the app actually writes to are
# owned by it; the code and the compiled assets stay read-only.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p log tmp/pids && \
    chown -R rails:rails log tmp
USER 1000:1000

EXPOSE 3000

# No entrypoint script: there is no database to prepare and no migration to
# run. Puma reads config/puma.rb, which takes PORT from the environment.
CMD ["./bin/rails", "server"]
