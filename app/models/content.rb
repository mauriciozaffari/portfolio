# The curated Markdown corpus under data/<locale>/**/*.md, and the gates that
# keep it publishable. See features/curated-content/SPEC.md.
module Content
  # Raised when a file on disk does not satisfy the schema. Loading is
  # all-or-nothing: an invalid record aborts the load rather than being skipped,
  # because a skipped record is an invisible content outage.
  class InvalidRecord < StandardError; end

  class << self
    def root
      Rails.root.join("data")
    end

    # Every file under `root`, dotfiles included, in path order.
    #
    # One method rather than two calls, because the two gates that stand
    # between an uncurated file and a public repository — Repository.paths and
    # SafetyScanner#scan_tree — both walk this tree, and both walked it with a
    # plain `glob("**/*")`. Ruby's glob does not match a leading dot without
    # File::FNM_DOTMATCH, so data/en/.private-source.pdf was invisible to both
    # at once.
    #
    # FNM_DOTMATCH also yields the `.` entry for the root and for every
    # subdirectory; `select(&:file?)` drops those along with the directories
    # themselves, which is why no explicit `.`/`..` rejection is needed.
    def files_under(root)
      Pathname(root).glob("**/*", File::FNM_DOTMATCH).select(&:file?).sort
    end

    # Memoized in production, rebuilt per call in development so that editing a
    # Markdown file shows up without restarting the server. The corpus is a few
    # dozen small files, so rebuilding costs less than watching the tree would.
    #
    # The memo is primed during boot by config/initializers/content.rb, so the
    # first reader is never the first thing to discover a broken corpus.
    def repository
      return Repository.load(root) if Rails.application.config.enable_reloading

      @repository ||= Repository.load(root)
    end
  end
end
