# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecordSet do
  subject(:record_set) { described_class.new(locale: 'en') }

  describe '.type_names' do
    it 'names every endpoint the API exposes' do
      expect(described_class.type_names).to eq(
        %w[profile leadership experience case-studies projects skills education metrics]
      )
    end
  end

  describe '.known_type?' do
    it 'accepts a published name and rejects anything else' do
      expect(described_class.known_type?('profile')).to be(true)
      expect(described_class.known_type?('widgets')).to be(false)
    end
  end

  describe '#serialize' do
    it 'returns a single object for the singular profile type' do
      expect(record_set.serialize('profile')).to include('id' => 'site-profile', 'name' => 'Mauricio Zaffari')
    end

    it 'returns the single leadership record with its title' do
      expect(record_set.serialize('leadership')).to include('id' => 'leadership', 'title' => a_string_matching(/\S/))
    end

    it 'returns an array of records for a collection type' do
      records = record_set.serialize('experience')

      expect(records).to be_an(Array)
      expect(records).to all(include('type' => 'experience'))
    end

    it 'keeps the record prose and drops the front matter keys every response already carries' do
      record = record_set.serialize('projects').first

      expect(record).to include('body', 'updated', 'locale')
      expect(record.keys).not_to include('status', 'confidentiality')
    end
  end

  describe '#all' do
    it 'returns every type the API can serve' do
      records = record_set.all
      types = records.pluck('type').uniq

      expect(types).to match_array(
        %w[site_profile leadership experience case_study metric open_source skill_group education]
      )
    end
  end

  describe '#search' do
    it 'finds a keyword in a record body' do
      matches = record_set.search('PostgreSQL')

      expect(matches).not_to be_empty
      expect(matches.map(&:to_json).join).to include('PostgreSQL')
    end

    it 'matches case-insensitively on any field' do
      expect(record_set.search('postgresql')).to eq(record_set.search('PostgreSQL'))
    end

    it 'returns nothing for a blank query rather than everything' do
      expect(record_set.search('   ')).to be_empty
    end

    it 'returns nothing when the corpus does not mention the term' do
      expect(record_set.search('cobol-on-mainframes')).to be_empty
    end
  end
end
