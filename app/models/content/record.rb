# frozen_string_literal: true

require 'forwardable'

module Content
  # One curated file: YAML front matter plus a Markdown body.
  #
  # Every failure here raises rather than warns. A record that quietly fails to
  # load is a section that quietly disappears from the page, and on this site the
  # content is the product.
  class Record
    include ActiveModel::Validations
    extend Forwardable

    # `id` values and filenames are kebab-case, and `id` always equals its
    # filename without the extension. That pairing is what lets a record be
    # located from a citation alone.
    ID_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

    validate :required_keys_are_present
    validate :type_is_known
    validate :identifier_matches_the_filename
    validate :enumerations_are_in_the_vocabulary
    validate :locale_matches_the_directory
    validate :type_rules_are_met
    validate :prose_stays_out_of_the_front_matter
    validate :restricted_records_are_not_published

    attr_reader :file

    def_delegators :file, :source, :directory_locale, :filename_id, :front_matter
    def_delegator :attributes, :[], :[]

    class << self
      # Reads and validates the record at `path`. `root` is the content root;
      # paths are reported relative to it so that a failure message reads the
      # same on every machine.
      def load(path, root:)
        new(file: RecordFile.read(path, root:)).tap(&:validate_or_raise)
      end
    end

    def initialize(file:)
      @file = file
    end

    def body = file.body.to_s

    def validate_or_raise
      return self if valid?

      raise InvalidRecord, "#{source}: #{errors.full_messages.join('; ')}"
    end

    def attributes
      @attributes ||= front_matter.with_indifferent_access.freeze
    end

    def id = attributes[:id]
    def type = attributes[:type]
    def locale = attributes[:locale]
    def status = attributes[:status]
    def confidentiality = attributes[:confidentiality]
    def updated = attributes[:updated]

    def published?
      status == 'published'
    end

    def restricted?
      confidentiality == 'restricted'
    end

    def renderable?
      published? && !restricted?
    end

    def html
      @html ||= Markdown.to_html(body)
    end

    def schema
      Schema.fetch(type)
    end

    private

    def required_keys_are_present
      absent = Schema::COMMON_KEYS.reject { |key| attributes[key].present? }

      absent.each { |key| errors.add :base, "front matter is missing the required key `#{key}`" }
    end

    def type_is_known
      return unless type
      return if schema

      errors.add :base, "`type` is `#{type}`, which is not one of #{Schema::NAMES.join(', ')}"
    end

    def identifier_matches_the_filename
      return unless id

      errors.add :base, "`id` is `#{id}`, which is not kebab-case" unless ID_FORMAT.match?(id)
      errors.add :base, "`id` is `#{id}` but the filename says `#{filename_id}`" unless id == filename_id
    end

    def enumerations_are_in_the_vocabulary
      reject_value :locale, Schema::LOCALES
      reject_value :status, Schema::STATUSES
      reject_value :confidentiality, Schema::CONFIDENTIALITIES
      reject_value :prominence, Schema::PROMINENCES if type == 'experience'
    end

    def locale_matches_the_directory
      if !directory_locale
        errors.add :base, 'is not inside a locale directory'
      elsif locale && locale != directory_locale
        errors.add :base, "`locale` is `#{locale}` but the file sits under `#{directory_locale}`"
      end
    end

    def type_rules_are_met
      known = schema
      return unless known

      TypeRules.new(record: self, schema: known).violations.each { |message| errors.add :base, message }
    end

    def prose_stays_out_of_the_front_matter
      Schema::FORBIDDEN_KEYS.each do |key|
        next unless attributes.key?(key)

        errors.add :base, "front matter carries `#{key}`, which belongs in the body and nowhere else"
      end
    end

    def restricted_records_are_not_published
      return unless published? && restricted?

      errors.add :base, 'is `published` and `restricted` at once, which cannot be honoured'
    end

    def reject_value(key, allowed)
      value = attributes[key]
      return unless value
      return if allowed.include?(value)

      errors.add :base, "`#{key}` is `#{value}`, which is not one of #{allowed.join(', ')}"
    end
  end
end
