# frozen_string_literal: true

require 'rails_helper'

# The sheet is the only place Prawn is asked for a page, so the two pieces of
# behaviour a record cannot reach — a widow guard that does fire, and a blank
# meta row — are exercised here rather than through a whole document.
RSpec.describe Resume::Sheet do
  subject(:sheet) { described_class.new(info: {}) }

  it 'draws nothing for a meta row whose values are all blank' do
    expect(sheet.meta([nil, ''])).to be_nil
  end

  it 'breaks to a new page when there is not enough room to keep a block together' do
    expect { sheet.keep_together(100_000) }.to change { sheet.pdf.page_count }.from(1).to(2)
  end
end
