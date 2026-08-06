# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"

  # `herb analyze` rather than `herb lint`: the lint subcommand shells out to
  # npx, and this application has no Node toolchain.
  step "Style: ERB", "bin/herb analyze app/views"

  step "Content: record schema", "bin/rails content:validate"

  # data/** is world-readable the moment it is pushed, so the scan and the path
  # gate are what replace human review with a failing build.
  step "Security: Content safety scan", "bin/rails content:scan"

  step "Security: Filesystem paths outside the app root", "bin/rails content:paths"

  step "Security: Importmap vulnerability audit", "bin/importmap audit"

  step "Tests", "bin/rspec"
end
