# frozen_string_literal: true

module Content
  # One curated file as it sits on disk, before it is a record: where it lives,
  # what it is called, and the YAML front matter and Markdown body it splits
  # into.
  #
  # Parsing is separate from validating so that a file which cannot be parsed
  # fails with a message about the file, and one that parses is judged by
  # Content::Record against the schema.
  FRONT_MATTER = /\A---[ \t]*\R(?<front_matter>.*?)^---[ \t]*\R(?<body>.*)\z/m

  RecordFile = Data.define(:source, :directory_locale, :filename_id, :front_matter, :body) do
    class << self
      # `root` is the content root; paths are reported relative to it so that a
      # failure message reads the same on every machine.
      def read(path, root:)
        relative = path.relative_path_from(root)
        source = root.basename.join(relative).to_s
        parsed = FRONT_MATTER.match(path.read)
        raise InvalidRecord, "#{source}: does not open with a YAML front matter block" unless parsed

        new(source:, directory_locale: locale_directory(relative), filename_id: path.basename('.md').to_s,
            front_matter: parse_front_matter(parsed[:front_matter], source), body: parsed[:body])
      end

      private

      # nil for a file sitting outside a locale directory, which is a defect
      # the record reports on itself.
      def locale_directory(relative)
        names = relative.each_filename.to_a
        names.first if names.length > 1
      end

      def parse_front_matter(yaml, source)
        parsed = YAML.safe_load(yaml, permitted_classes: [Date, Time])
        return parsed if parsed.is_a?(Hash)

        raise InvalidRecord, "#{source}: front matter is not a set of key/value pairs"
      rescue Psych::Exception => e
        raise InvalidRecord, "#{source}: front matter is not valid YAML (#{e.message})"
      end
    end
  end
end
