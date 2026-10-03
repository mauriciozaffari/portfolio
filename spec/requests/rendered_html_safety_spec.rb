# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rendered HTML safety' do
  # Driven by the routing table rather than by a list of today's pages, so a
  # route a later feature adds is scanned the moment it exists. Routes with a
  # required dynamic segment are skipped, because there is no honest way to
  # invent a value for one here; their content is covered by the data/** scan.
  def scannable_paths
    Rails.application.routes.routes.filter_map do |route|
      next if route.internal
      next unless route.verb.include?('GET')
      next unless route.path.required_names.empty?

      route.path.spec.to_s.delete_suffix('(.:format)')
    end.uniq
  end

  it 'has pages to scan' do
    expect(scannable_paths).to include('/')
  end

  it 'publishes nothing that must never be published' do
    scanner = Content::SafetyScanner.new

    findings = scannable_paths.flat_map do |path|
      get path
      next [] unless response.media_type == 'text/html'

      scanner.scan_html(response.body, source: path)
    end

    expect(findings.map(&:to_s)).to be_empty
  end
end
