# frozen_string_literal: true

module Content
  # The checks that only make sense once a record's `type` is known to be one of
  # the vocabulary: which keys that type requires, and whether it carries prose
  # in the body or none at all.
  #
  # Held apart from Content::Record so a record with an unknown type is reported
  # once, by `type_is_known`, instead of once more by every check that needs a
  # schema to compare against.
  class TypeRules
    attr_reader :record, :schema

    def initialize(record:, schema:)
      @record = record
      @schema = schema
    end

    # Messages only; the caller decides what a failure means.
    def violations
      [*missing_keys, *body_violation]
    end

    private

    def missing_keys
      required = schema.required_keys.reject { |key| record[key].present? }
      required.map { |key| "a `#{record.type}` is missing the required key `#{key}`" }
    end

    def body_violation
      if schema.body == :required
        body_required_violation
      else
        body_forbidden_violation
      end
    end

    def body_required_violation
      return [] if record.body.present?

      ["a `#{record.type}` carries its prose in the body, and this one has none"]
    end

    def body_forbidden_violation
      return [] if record.body.blank?

      ["a `#{record.type}` is entirely structured, so its body must be empty"]
    end
  end
end
