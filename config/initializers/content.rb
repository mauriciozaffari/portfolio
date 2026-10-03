# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Read the corpus during boot, so that an invalid record stops the process
# instead of waiting for a reader.
#
# /up is Rails' own health controller: it renders a static page and never
# touches Content. A corpus that fails to load therefore had no way of
# reaching the Kamal healthcheck, which would go green on a container that
# then answered every real request with a 500. The alternative fix — teaching
# /up to load the corpus — would buy the same guarantee by making the
# healthcheck the most expensive thing the container does, several times a
# minute, forever. Loading here instead pays for it once.
#
# Gated on reloading rather than on Rails.env, for two reasons. Development
# rebuilds per call (see Content.repository) and must keep doing so. And
# `rails content:validate` runs in development, where it reports an invalid
# record through its own abort message; boot-loading there would replace that
# message with a backtrace from this file.
Rails.application.config.after_initialize do
  Content.repository unless Rails.application.config.enable_reloading
end
