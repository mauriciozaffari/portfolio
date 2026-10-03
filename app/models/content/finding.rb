# frozen_string_literal: true

module Content
  # Where a gate fired, and why.
  #
  # Deliberately without an excerpt. CI output for a public repository is itself
  # a published surface, so printing the offending value would disclose exactly
  # what the gate had just caught. A file and a line number are enough to find it
  # locally, where looking is free.
  Finding = Data.define(:reason, :source, :line) do
    def to_s
      "#{source}:#{line}: #{reason}"
    end
  end
end
