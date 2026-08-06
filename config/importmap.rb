# Pin npm packages by running ./bin/importmap
#
# Nothing is pinned, because the landing page ships no JavaScript.
#
# Turbo Drive was measured before it was dropped: 105,579 bytes uncompressed,
# 61% of the page's entire transfer, in exchange for avoiding one full page load
# on the locale switch — the only navigation this site has. Stimulus would have
# shipped the framework and its loader to register zero controllers. Neither
# earns its place under features/landing-page/SPEC.md.
#
# The gems stay in the Gemfile: app-foundation owns the dependency set, and
# `bin/importmap audit` stays in bin/ci so that a pin cannot arrive unaudited.
# `bin/rails turbo:install` and `stimulus:install` restore the pipeline when a
# feature genuinely needs it.
