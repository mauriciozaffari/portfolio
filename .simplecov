# frozen_string_literal: true

# Native SimpleCov configuration, applied before rails-quality-assurance starts
# coverage. Add any SimpleCov option here (track_tests, group,
# maximum_coverage_drop, ...) without waiting on a rails-quality-assurance release.
SimpleCov.configure do
  cover_views
end
