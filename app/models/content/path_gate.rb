module Content
  # AGENTS.md rule 4: the private source material behind data/** is never read
  # by the application, in any environment.
  #
  # The durable proof of that is the absence of any absolute path pointing
  # outside the application root, so this walks the code and asserts there is
  # none. A path that is not written down cannot be opened by accident, and it
  # cannot be published in a stack trace either.
  class PathGate
    DIRECTORIES = [ "app", "lib", "config" ].freeze

    # Encrypted credentials and key material are opaque bytes rather than code,
    # and this file necessarily contains the literals it searches for.
    SKIPPED = [
      "config/credentials.yml.enc",
      "config/master.key",
      "app/models/content/path_gate.rb"
    ].freeze

    # Each pattern is anchored so that a URL path cannot trip it: what matters
    # is a filesystem location written into the source, not a route that happens
    # to share a name.
    PATTERNS = [
      %r{(?<![\w.])/home/},
      %r{(?<![\w.])/Users/},
      %r{(?<![\w.])/mnt/},
      %r{(?<![\w.])/media/},
      %r{(?<![\w.])/srv/},
      %r{(?<![\w.])/root/},
      %r{(?:\A|[\s"'(=])~/},
      /\b[A-Za-z]:\\/
    ].freeze

    REASON = "filesystem path outside the application root".freeze

    attr_reader :root

    def initialize(root)
      @root = Pathname(root)
    end

    def findings
      files.flat_map do |path|
        text = path.read
        next [] unless text.valid_encoding?

        offending_lines(text).map do |number|
          Finding.new(reason: REASON, source: path.relative_path_from(root).to_s, line: number)
        end
      end
    end

    private
      def files
        DIRECTORIES.flat_map { |directory| root.glob("#{directory}/**/*") }
                   .select(&:file?)
                   .reject { |path| SKIPPED.include?(path.relative_path_from(root).to_s) }
                   .sort
      end

      def offending_lines(text)
        text.each_line.with_index(1).filter_map do |line, number|
          number if PATTERNS.any? { |pattern| pattern.match?(line) }
        end
      end
  end
end
