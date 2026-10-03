# frozen_string_literal: true

# The read-only JSON view of the curated records.
#
# One serializer for both the REST API and the MCP tools, so the two protocols
# cannot describe the same record differently. Values come out of
# Content::Repository untouched; this class decides shape and ordering only.
class RecordSet
  TYPES = {
    'profile' => :site_profile,
    'leadership' => :leadership,
    'experience' => :experience,
    'case-studies' => :case_study,
    'projects' => :open_source,
    'skills' => :skill_group,
    'education' => :education,
    'metrics' => :metric
  }.freeze

  def self.type_names = TYPES.keys.freeze

  def self.known_type?(name) = TYPES.key?(name.to_s)

  attr_reader :locale, :repository

  def initialize(locale:, repository: Content.repository)
    @locale = locale.to_s
    @repository = repository
  end

  # Every record the site publishes, for the agent that would rather page
  # through one response than discover eight endpoints.
  def all
    TYPES.keys.flat_map { |name| serialize(name) }
  end

  def serialize(type)
    records = entries(type)

    %w[profile leadership].include?(type.to_s) ? records.first : records
  end

  def found?(type) = self.class.known_type?(type)

  # Case-insensitive across every field and body, so an agent can answer
  # "does this person know Terraform?" without knowing which record type would
  # carry it.
  def search(query)
    needle = query.to_s.downcase.strip
    return [] if needle.empty?

    all.select { |record| mentions?(record, needle) }
  end

  private

  def mentions?(record, needle)
    record.values.any? { |value| value.to_s.downcase.include?(needle) }
  end

  def entries(type)
    name = type.to_s

    case name
    when 'profile'
      [repository.site_profile(locale:)].compact.map { |entry| profile(entry) }
    when 'leadership'
      [repository.leadership(locale:)].compact.map { |entry| prose(entry, 'title') }
    else
      repository.of_type(TYPES.fetch(name), locale:).map { |entry| record(entry) }
    end
  end

  def profile(entry)
    record = entry.record

    {
      'id' => record.id,
      'type' => record.type,
      'name' => record[:name],
      'headline' => record[:headline],
      'region' => record[:region],
      'timezone' => record[:timezone],
      'work_mode' => record[:work_mode],
      'links' => Array(record[:links]).map { |link| { 'label' => link[:label], 'url' => link[:url] } },
      'body' => record.body.to_s.strip,
      'updated' => record[:updated],
      'locale' => record.locale
    }
  end

  def prose(entry, title_key)
    record = entry.record

    {
      'id' => record.id,
      'type' => record.type,
      'title' => record[title_key.to_sym],
      'body' => record.body.to_s.strip,
      'updated' => record[:updated],
      'locale' => record.locale
    }
  end

  # Front matter minus the keys every response already carries, so a consumer
  # reads only what it does not already know.
  def record(entry)
    source = entry.record
    extra = source.attributes.except(*Content::Schema::COMMON_KEYS)

    extra.transform_keys(&:to_s).merge(
      'id' => source.id,
      'type' => source.type,
      'body' => source.body.to_s.strip,
      'updated' => source[:updated],
      'locale' => source.locale
    )
  end
end
