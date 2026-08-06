# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"

  # `herb analyze` rather than `herb lint`: the lint subcommand shells out to
  # npx, and this application has no Node toolchain.
  step "Style: ERB", "bin/herb analyze app/views"

  step "Security: Importmap vulnerability audit", "bin/importmap audit"

  step "Tests", "bin/rspec"
end
