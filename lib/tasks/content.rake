# frozen_string_literal: true

namespace :content do
  desc 'Validate every record under data/ against the front matter schema'
  task validate: :environment do
    repository = Content::Repository.load(Content.root)
    puts "#{repository.records.size} records valid across #{repository.locales.join(', ')}."
  rescue Content::InvalidRecord => e
    abort e.message
  end

  desc 'Scan data/ for anything that must never be published'
  task scan: :environment do
    findings = Content::SafetyScanner.new.scan_tree(Content.root)
    abort ['Content safety scan failed:', *findings.map { |finding| "  #{finding}" }].join("\n") if findings.any?

    puts "Nothing unpublishable found under #{Content.root.basename}/."
  end

  desc 'Assert no application code reads a filesystem path outside the app root'
  task paths: :environment do
    findings = Content::PathGate.new(Rails.root).findings
    abort ['Path gate failed:', *findings.map { |finding| "  #{finding}" }].join("\n") if findings.any?

    puts 'No filesystem paths outside the application root.'
  end
end
