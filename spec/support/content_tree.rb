# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

# Builds throwaway content trees, so a spec can describe one deliberately broken
# record without touching data/ — which holds reviewed, published content and is
# never a test fixture.
module ContentTree
  MINIMUM = {
    'site_profile' => { 'name' => 'Example Person', 'headline' => 'Example headline',
                        'links' => [{ 'label' => 'Example', 'url' => 'https://example.com' }] },
    'leadership' => { 'title' => 'Example title' },
    'experience' => { 'organization' => 'Example Org', 'role' => 'Example Role', 'start_date' => '2020',
                      'prominence' => 'primary' },
    'case_study' => { 'title' => 'Example', 'organization' => 'Example Org', 'period' => '2020',
                      'technologies' => ['Ruby'] },
    'metric' => { 'label' => 'Example', 'value' => '1', 'context' => 'Example context' },
    'open_source' => { 'name' => 'example', 'role' => 'Creator', 'url' => 'https://example.com' },
    'skill_group' => { 'label' => 'Example', 'items' => ['Ruby'] },
    'education' => { 'institution' => 'Example', 'credential' => 'Example', 'year' => '2020' }
  }.freeze

  def content_root
    @content_root ||= Pathname(Dir.mktmpdir('content-spec'))
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
  #
  # `body` and `path` describe the file rather than the front matter, and `locale`
  # does both: it is a front matter key and it names the directory. They are read
  # out of the overrides first, so everything left is front matter.
  def write_record(id, type:, **overrides)
    locale = overrides.fetch(:locale, 'en')
    path = overrides.delete(:path) || "#{locale}/#{id}.md"
    body = overrides.delete(:body) { :default }

    attributes = {
      'id' => id, 'type' => type, 'locale' => locale,
      'status' => 'published', 'confidentiality' => 'public', 'updated' => '2026-01-01'
    }.merge(MINIMUM.fetch(type, {})).merge(overrides.stringify_keys).compact

    write_file(path, record_source(attributes, resolve_body(type, id, body)))
  end

  def write_locale_singletons(locale: 'en')
    write_record('site-profile', type: 'site_profile', locale:)
    write_record('leadership', type: 'leadership', locale:)
  end

  def load_record(path)
    Content::Record.load(path, root: content_root)
  end

  def load_repository
    Content::Repository.load(content_root)
  end

  # Points the application's own loader at the throwaway tree, for a spec that
  # needs a rendered page or a built PDF rather than a repository object.
  #
  # The memoized repository has to be dropped on both sides of the example.
  # Reloading is off in the test environment, so the first corpus a process loads
  # is otherwise the only one it ever sees: either the real one answers a
  # fixture's example, or a fixture answers the next spec's.
  def serve_fixture_corpus
    @fixture_corpus = true
    reset_repository
    allow(Content).to receive(:root).and_return(content_root)
  end

  def reset_repository
    Content.remove_instance_variable(:@repository) if Content.instance_variable_defined?(:@repository)
  end

  private

  def record_source(attributes, body)
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

  config.after do
    reset_repository if @fixture_corpus
    remove_content_root
  end
end
