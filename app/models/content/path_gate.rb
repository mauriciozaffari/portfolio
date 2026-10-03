# frozen_string_literal: true

module Content
  # AGENTS.md rule 4: the private source material behind data/** is never read
  # by the application, in any environment.
  #
  # The durable proof of that is the absence of any absolute path pointing
  # outside the application root, so this walks the code and asserts there is
  # none. A path that is not written down cannot be opened by accident, and it
  # cannot be published in a stack trace either.
  class PathGate
    DIRECTORIES = %w[app lib config].freeze

    # Encrypted credentials and key material are opaque bytes rather than code,
    # and this file necessarily contains the literals it searches for.
    SKIPPED = [
      'config/credentials.yml.enc',
      'config/master.key',
      'app/models/content/path_gate.rb'
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

    REASON = 'filesystem path outside the application root'

    attr_reader :root

    def initialize(root)
      @root = Pathname(root)
    end

    def findings
      files.flat_map { |path| findings_in(path) }
    end

    private

    def findings_in(path)
      text = path.read
      return [] unless text.valid_encoding?

      source = path.relative_path_from(root).to_s
      offending_lines(text).map { |number| Finding.new(reason: REASON, source:, line: number) }
    end

    def files
      DIRECTORIES.flat_map { |directory| root.glob("#{directory}/**/*") }
                 .select(&:file?)
                 .reject { |path| SKIPPED.include?(path.relative_path_from(root).to_s) }
                 .sort
    end

    def offending_lines(text)
      numbered = text.each_line.with_index(1)
      numbered.filter_map { |line, number| number if offending?(line) }
    end

    def offending?(line)
      PATTERNS.any? { |pattern| pattern.match?(line) }
    end
  end
end
