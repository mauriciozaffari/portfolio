require "fileutils"
require "tmpdir"

# Builds throwaway content trees, so a spec can describe one deliberately broken
# record without touching data/ — which holds reviewed, published content and is
# never a test fixture.
module ContentTree
  MINIMUM = {
    "site_profile" => { "name" => "Example Person", "headline" => "Example headline", "links" => [ "https://example.com" ] },
    "leadership" => { "title" => "Example title" },
    "experience" => { "organization" => "Example Org", "role" => "Example Role", "start_date" => "2020", "prominence" => "primary" },
    "case_study" => { "title" => "Example", "organization" => "Example Org", "period" => "2020", "technologies" => [ "Ruby" ] },
    "metric" => { "label" => "Example", "value" => "1", "context" => "Example context" },
    "open_source" => { "name" => "example", "role" => "Creator", "url" => "https://example.com" },
    "skill_group" => { "label" => "Example", "items" => [ "Ruby" ] },
    "education" => { "institution" => "Example", "credential" => "Example", "year" => "2020" }
  }.freeze

  def content_root
    @content_root ||= Pathname(Dir.mktmpdir("content-spec"))
  end

  def remove_content_root
    FileUtils.remove_entry(@content_root) if @content_root
  end

  def write_file(relative_path, contents)
    content_root.join(relative_path).tap do |path|
      path.dirname.mkpath
      path.write(contents)
    end
  end

  # Passing a key as nil removes it, which is how a spec describes a record with
  # a required key missing.
  def write_record(id, type:, locale: "en", body: :default, path: nil, **overrides)
    attributes = {
      "id" => id, "type" => type, "locale" => locale,
      "status" => "published", "confidentiality" => "public", "updated" => "2026-01-01"
    }.merge(MINIMUM.fetch(type, {})).merge(overrides.stringify_keys).compact

    write_file(path || "#{locale}/#{id}.md", document(attributes, resolve_body(type, id, body)))
  end

  def write_locale_singletons(locale: "en")
    write_record("site-profile", type: "site_profile", locale: locale)
    write_record("leadership", type: "leadership", locale: locale)
  end

  def load_record(path)
    Content::Record.load(path, root: content_root)
  end

  def load_repository
    Content::Repository.load(content_root)
  end

  private
    def document(attributes, body)
      front_matter = attributes.to_yaml.delete_prefix("---\n")
      body.present? ? "---\n#{front_matter}---\n\n#{body}\n" : "---\n#{front_matter}---\n"
    end

    def resolve_body(type, id, body)
      return body unless body == :default
      return unless Content::Schema.fetch(type)&.body == :required

      "Example prose for #{id}."
    end
end

RSpec.configure do |config|
  config.include ContentTree
  config.after { remove_content_root }
end
