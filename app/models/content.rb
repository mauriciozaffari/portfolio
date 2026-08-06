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

    # Memoized in production, rebuilt per call in development so that editing a
    # Markdown file shows up without restarting the server. The corpus is a few
    # dozen small files, so rebuilding costs less than watching the tree would.
    def repository
      return Repository.load(root) if Rails.application.config.enable_reloading

      @repository ||= Repository.load(root)
    end
  end
end
