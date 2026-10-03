# frozen_string_literal: true

require 'pdf-reader'

# Reads a generated PDF the way everything downstream of a download does.
#
# The point of going through a parser rather than through the builder's own
# state is that the bytes are what circulates. A gate applied to the objects
# that produced the file proves the builder was asked nicely; a gate applied to
# the extracted text proves what a reader, a recruiter's ATS, or a scraper
# actually gets.
module PdfText
  def pdf_reader(bytes)
    PDF::Reader.new(StringIO.new(bytes))
  end

  # Both of the readings a downstream tool can arrive at, concatenated, because
  # the scan that runs over this must not be able to miss a shape either of them
  # would show.
  #
  # `PDF::Reader::Page#text` rebuilds a character grid using the page's median
  # font size, which keeps a wrapped line whole but silently merges two lines
  # set closer together than that median — and a merge reorders words. The
  # positioned runs are the drawing operations themselves: never merged, never
  # reordered, but split wherever a bold or a link fragment starts. Neither is
  # wrong; each hides what the other shows.
  def pdf_text(bytes)
    pdf_reader(bytes).pages.flat_map { |page| positioned_lines(page) << page.text }.join("\n")
  end

  # Every run in reading order on one line, for asking whether a sentence made
  # it into the document at all. Not used for scanning: joining the whole page
  # into one string invents adjacencies a reader never sees, and a gate should
  # not fire on two values that only touch because a gutter label happens to
  # precede a paragraph.
  def pdf_flowed(bytes)
    pdf_reader(bytes).pages.flat_map { |page| positioned_lines(page) }.join(' ').squish
  end

  def positioned_lines(page)
    receiver = PDF::Reader::PageTextReceiver.new
    page.walk(receiver)

    receiver.runs.sort_by { |run| [-run.y, run.x] }.map(&:text)
  end

  def pdf_info(bytes)
    pdf_reader(bytes).info
  end
end

RSpec.configure do |config|
  config.include PdfText
end
