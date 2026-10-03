# frozen_string_literal: true

module Content
  # The record vocabulary from features/curated-content/SPEC.md, written down
  # once so the loader, the specs, and any future authoring tool cannot drift
  # apart from each other or from the spec.
  module Schema
    # The closed vocabularies a front-matter value is checked against.
    module Vocabulary
      LOCALES = %w[en pt-BR].freeze
      DEFAULT_LOCALE = 'en'
      STATUSES = %w[draft published].freeze
      CONFIDENTIALITIES = %w[public restricted].freeze
      PROMINENCES = %w[primary secondary].freeze
    end

    # The keys the front matter may and may not carry.
    module Keys
      # Required on every record whatever its type.
      COMMON_KEYS = %w[id type locale status confidentiality updated].freeze

      # Front matter carries structured metadata and the body carries prose; a
      # value never lives in both, because that is how the two drift apart.
      # `summary` is the key that keeps being tempting, so it is rejected outright.
      FORBIDDEN_KEYS = ['summary'].freeze
    end

    include Vocabulary
    include Keys

    # `body` is :required when the type's prose is the point of the record, and
    # :none when the type is entirely structured and a body would duplicate it.
    Type = Data.define(:name, :required_keys, :body, :singular)

    TYPES = [
      Type.new(name: 'site_profile', required_keys: %w[name headline links], body: :required, singular: true),
      Type.new(name: 'leadership', required_keys: ['title'], body: :required, singular: true),
      Type.new(name: 'experience', required_keys: %w[organization role start_date prominence],
               body: :required, singular: false),
      Type.new(name: 'case_study', required_keys: %w[title organization period technologies],
               body: :required, singular: false),
      Type.new(name: 'metric', required_keys: %w[label value context], body: :none, singular: false),
      Type.new(name: 'open_source', required_keys: %w[name role url], body: :required, singular: false),
      Type.new(name: 'skill_group', required_keys: %w[label items], body: :none, singular: false),
      Type.new(name: 'education', required_keys: %w[institution credential year], body: :none, singular: false)
    ].index_by(&:name).freeze

    NAMES = TYPES.keys.freeze
    SINGULAR_NAMES = TYPES.values.select(&:singular).map(&:name).freeze

    def self.fetch(name)
      TYPES[name]
    end
  end
end
