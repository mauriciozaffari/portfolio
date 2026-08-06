require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

# Requires supporting files with custom matchers and macros in spec/support.
Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |file| require file }

RSpec.configure do |config|
  # This application has no database. Active Record is not part of the stack —
  # see features/app-foundation/SPEC.md.
  config.use_active_record = false

  config.filter_rails_from_backtrace!
end
