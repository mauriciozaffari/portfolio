# Demotes the headings inside a rendered record body so the record composes into
# a page without claiming the page's outline.
#
# The four case studies open with `## Problem`, which kramdown renders as `<h2>`.
# On this page a case study title is already an `<h3>`, so an untouched body
# would put "Problem" at the same level as the section that contains it and turn
# the document outline into nonsense. Shifting is the standard fix — it is what
# every static-site generator calls a heading offset — and it belongs here
# rather than in Content::Markdown, because the offset is a property of where
# the page puts the body, not of the record.
#
# Operating on HTML with a regular expression is safe in this one direction: the
# input has already been through Content::Markdown's sanitizer, whose allowlist
# admits `h2`, `h3` and `h4` with no attributes at all, so a heading tag cannot
# carry anything for the pattern to miss.
module HeadingLevels
  HEADING = %r{<(?<closing>/?)h(?<level>[1-6])>}
  DEEPEST = 6

  def self.shift(html, by:)
    shifted = html.to_s.gsub(HEADING) do
      match = Regexp.last_match
      "<#{match[:closing]}h#{demote(match[:level], by)}>"
    end

    ActiveSupport::SafeBuffer.new(shifted)
  end

  def self.demote(level, by)
    [ level.to_i + by, DEEPEST ].min
  end
  private_class_method :demote
end
