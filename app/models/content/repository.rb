module Content
  # Every record on disk, validated as a set.
  #
  # A record validates itself; the repository owns the invariants that only
  # exist between records — how many of a type a locale may have, and the
  # pairing that lets one language stand in for the other.
  class Repository
    attr_reader :root, :records

    def self.load(root)
      root = Pathname(root)
      new(root: root, records: paths(root).map { |path| Record.load(path, root: root) })
    end

    # data/ is a corpus, not a directory anyone drops files into. A PDF or a
    # spreadsheet left here is the raw copy this whole feature exists to
    # prevent, and the loader would otherwise ignore it all the way to
    # production.
    def self.paths(root)
      files = root.glob("**/*").select(&:file?).sort
      strays = files.reject { |file| file.extname == ".md" }
      return files if strays.empty?

      names = strays.map { |file| file.relative_path_from(root).to_s }
      raise InvalidRecord, "#{root.basename}: holds Markdown records and nothing else, but found #{names.join(", ")}"
    end
    private_class_method :paths

    def initialize(root:, records:)
      @root = root
      @records = records.freeze
      enforce_cardinality!
    end

    def locales
      records.map(&:locale).uniq.sort
    end

    # Published and unrestricted only. Every locale-aware query below is built
    # on this, so a draft or restricted record has no route to a view.
    def renderable
      @renderable ||= records.select(&:renderable?).freeze
    end

    # Records of `type` for `locale`, in id order, each wrapped so a view can
    # tell whether it is showing the language it asked for.
    def of_type(type, locale:)
      renderable.select { |record| record.type == type.to_s }
                .group_by(&:id)
                .sort_by(&:first)
                .map { |_id, versions| Localized.new(record: preferred(versions, locale), requested_locale: locale) }
    end

    def site_profile(locale:)
      of_type(:site_profile, locale: locale).first
    end

    def leadership(locale:)
      of_type(:leadership, locale: locale).first
    end

    private
      def preferred(versions, locale)
        versions.find { |record| record.locale == locale } ||
          versions.find { |record| record.locale == Schema::DEFAULT_LOCALE } ||
          versions.min_by(&:locale)
      end

      def enforce_cardinality!
        records.group_by(&:locale).each do |locale, group|
          Schema::SINGULAR_NAMES.each do |name|
            found = group.count { |record| record.type == name }
            next if found == 1

            raise InvalidRecord, "#{root.basename}/#{locale}: needs exactly one #{name} record, found #{found}"
          end
        end
      end
  end
end
