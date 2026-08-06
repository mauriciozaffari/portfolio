module Content
  # One curated file: YAML front matter plus a Markdown body.
  #
  # Every failure here raises rather than warns. A record that quietly fails to
  # load is a section that quietly disappears from the page, and on this site the
  # content is the product.
  class Record
    include ActiveModel::Validations

    # `id` values and filenames are kebab-case, and `id` always equals its
    # filename without the extension. That pairing is what lets a record be
    # located from a citation alone.
    ID_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
    FRONT_MATTER = /\A---[ \t]*\R(?<front_matter>.*?)^---[ \t]*\R(?<body>.*)\z/m

    validate :required_keys_are_present
    validate :type_is_known
    validate :identifier_matches_the_filename
    validate :enumerations_are_in_the_vocabulary
    validate :locale_matches_the_directory
    validate :type_keys_are_present
    validate :body_matches_the_type
    validate :prose_stays_out_of_the_front_matter
    validate :restricted_records_are_not_published

    attr_reader :source, :directory_locale, :filename_id, :front_matter, :body

    class << self
      # Reads and validates the record at `path`. `root` is the content root;
      # paths are reported relative to it so that a failure message reads the
      # same on every machine.
      def load(path, root:)
        relative = path.relative_path_from(root)
        source = root.basename.join(relative).to_s
        parsed = FRONT_MATTER.match(path.read)
        raise InvalidRecord, "#{source}: does not open with a YAML front matter block" if parsed.nil?

        new(
          source: source,
          directory_locale: locale_directory(relative),
          filename_id: path.basename(".md").to_s,
          front_matter: parse_front_matter(parsed[:front_matter], source),
          body: parsed[:body]
        ).tap(&:validate!)
      end

      private
        # nil for a file sitting outside a locale directory, which is a defect
        # the record reports on itself.
        def locale_directory(relative)
          names = relative.each_filename.to_a
          names.first if names.length > 1
        end

        def parse_front_matter(yaml, source)
          parsed = YAML.safe_load(yaml, permitted_classes: [ Date, Time ])
          return parsed if parsed.is_a?(Hash)

          raise InvalidRecord, "#{source}: front matter is not a set of key/value pairs"
        rescue Psych::Exception => error
          raise InvalidRecord, "#{source}: front matter is not valid YAML (#{error.message})"
        end
    end

    def initialize(source:, directory_locale:, filename_id:, front_matter:, body:)
      @source = source
      @directory_locale = directory_locale
      @filename_id = filename_id
      @front_matter = front_matter
      @body = body.to_s
    end

    def validate!
      return self if valid?

      raise InvalidRecord, "#{source}: #{errors.full_messages.join("; ")}"
    end

    def attributes
      @attributes ||= front_matter.with_indifferent_access.freeze
    end

    def [](key)
      attributes[key]
    end

    def id = attributes[:id]
    def type = attributes[:type]
    def locale = attributes[:locale]
    def status = attributes[:status]
    def confidentiality = attributes[:confidentiality]
    def updated = attributes[:updated]

    def published?
      status == "published"
    end

    def restricted?
      confidentiality == "restricted"
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
        missing(Schema::COMMON_KEYS).each do |key|
          errors.add :base, "front matter is missing the required key `#{key}`"
        end
      end

      def type_is_known
        return if type.nil? || schema

        errors.add :base, "`type` is `#{type}`, which is not one of #{Schema::NAMES.join(", ")}"
      end

      def identifier_matches_the_filename
        return if id.nil?

        errors.add :base, "`id` is `#{id}`, which is not kebab-case" unless ID_FORMAT.match?(id)
        errors.add :base, "`id` is `#{id}` but the filename says `#{filename_id}`" unless id == filename_id
      end

      def enumerations_are_in_the_vocabulary
        reject_value :locale, Schema::LOCALES
        reject_value :status, Schema::STATUSES
        reject_value :confidentiality, Schema::CONFIDENTIALITIES
        reject_value :prominence, Schema::PROMINENCES if type == "experience"
      end

      def locale_matches_the_directory
        if directory_locale.nil?
          errors.add :base, "is not inside a locale directory"
        elsif !locale.nil? && locale != directory_locale
          errors.add :base, "`locale` is `#{locale}` but the file sits under `#{directory_locale}`"
        end
      end

      def type_keys_are_present
        return unless schema

        missing(schema.required_keys).each do |key|
          errors.add :base, "a `#{type}` is missing the required key `#{key}`"
        end
      end

      def body_matches_the_type
        return unless schema

        if schema.body == :required && body.blank?
          errors.add :base, "a `#{type}` carries its prose in the body, and this one has none"
        elsif schema.body == :none && body.present?
          errors.add :base, "a `#{type}` is entirely structured, so its body must be empty"
        end
      end

      def prose_stays_out_of_the_front_matter
        Schema::FORBIDDEN_KEYS.each do |key|
          next unless attributes.key?(key)

          errors.add :base, "front matter carries `#{key}`, which belongs in the body and nowhere else"
        end
      end

      def restricted_records_are_not_published
        return unless published? && restricted?

        errors.add :base, "is `published` and `restricted` at once, which cannot be honoured"
      end

      def missing(keys)
        keys.reject { |key| attributes[key].present? }
      end

      def reject_value(key, allowed)
        value = attributes[key]
        return if value.nil? || allowed.include?(value)

        errors.add :base, "`#{key}` is `#{value}`, which is not one of #{allowed.join(", ")}"
      end
  end
end
