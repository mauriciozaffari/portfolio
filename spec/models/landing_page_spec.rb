# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LandingPage do
  def page(locale: 'en')
    described_class.new(repository: load_repository, locale:)
  end

  def ids(entries)
    entries.map { |entry| entry.record.id }
  end

  before { write_locale_singletons }

  describe 'experience' do
    it 'foregrounds the primary roles, newest first' do
      write_record('older', type: 'experience', start_date: '2015', prominence: 'primary')
      write_record('newer', type: 'experience', start_date: '2019-04', prominence: 'primary')

      expect(ids(page.current_roles)).to eq(%w[newer older])
    end

    it 'keeps the secondary roles instead of discarding them' do
      write_record('lead', type: 'experience', start_date: '2020', prominence: 'primary')
      write_record('aside', type: 'experience', start_date: '2011', prominence: 'secondary')

      expect(ids(page.current_roles)).to eq(['lead'])
      expect(ids(page.earlier_roles)).to eq(['aside'])
    end

    it 'orders a role that names its month after one in the same year that does not' do
      write_record('bare', type: 'experience', start_date: '2018', prominence: 'primary')
      write_record('dated', type: 'experience', start_date: '2018-07', prominence: 'primary')

      expect(ids(page.current_roles)).to eq(%w[dated bare])
    end

    it 'sorts a start_date that is not a date at all without inventing one' do
      write_record('undated', type: 'experience', start_date: 'ongoing', prominence: 'primary')
      write_record('dated', type: 'experience', start_date: '2020', prominence: 'primary')

      expect(ids(page.current_roles)).to eq(%w[dated undated])
    end
  end

  describe 'ordering where a record carries a date or a magnitude' do
    it 'puts the newest case study first, whatever shape its period has' do
      write_record('ranged', type: 'case_study', period: '2021 - 2022')
      write_record('single', type: 'case_study', period: '2026')

      expect(ids(page.case_studies)).to eq(%w[single ranged])
    end

    it 'puts the most downloaded project first and an uncounted one last' do
      write_record('small', type: 'open_source', downloads: 5216)
      write_record('large', type: 'open_source', downloads: 720_962)
      write_record('uncounted', type: 'open_source')

      expect(ids(page.projects)).to eq(%w[large small uncounted])
    end

    it 'puts the most recent credential first' do
      write_record('first', type: 'education', year: '2008')
      write_record('second', type: 'education', year: '2011')

      expect(ids(page.education)).to eq(%w[second first])
    end
  end

  describe 'ordering where a record carries neither' do
    it "leaves metrics in the loader's id order" do
      write_record('zeta', type: 'metric')
      write_record('alpha', type: 'metric')

      expect(ids(page.metrics)).to eq(%w[alpha zeta])
    end

    it "leaves skill groups in the loader's id order" do
      write_record('zeta', type: 'skill_group')
      write_record('alpha', type: 'skill_group')

      expect(ids(page.skill_groups)).to eq(%w[alpha zeta])
    end
  end

  describe 'when the content behind a locale last changed' do
    it 'ignores an updated value that is not a date rather than raising' do
      write_record('site-profile', type: 'site_profile', updated: 'soon')
      write_record('leadership', type: 'leadership', updated: 'soon')
      write_record('rails-years', type: 'metric', updated: 'soon')

      expect(page.updated).to be_nil
    end

    it 'reports the newest parseable date across every record' do
      write_record('site-profile', type: 'site_profile', updated: '2019-01-01')
      write_record('leadership', type: 'leadership', updated: '2019-01-01')
      write_record('newer', type: 'metric', updated: '2024-06-30')

      expect(page.updated).to eq(Date.new(2024, 6, 30))
    end
  end

  describe 'what a view can reach' do
    it 'cannot reach a draft record' do
      write_record('hidden', type: 'metric', status: 'draft')

      expect(page.metrics).to be_empty
    end

    it 'cannot reach a restricted record' do
      write_record('hidden', type: 'metric', status: 'draft', confidentiality: 'restricted')

      expect(page.metrics).to be_empty
    end
  end

  describe 'locale fallback' do
    it 'reports no substitution when every record is in the requested locale' do
      write_record('rails-years', type: 'metric')

      expect(page).not_to be_substituted
    end

    it 'reports a substitution when the requested locale has no records at all' do
      write_record('rails-years', type: 'metric')

      expect(page(locale: 'pt-BR')).to be_substituted
    end

    it 'still serves the whole page from the locale that does exist' do
      write_record('rails-years', type: 'metric')

      expect(ids(page(locale: 'pt-BR').metrics)).to eq(['rails-years'])
      expect(page(locale: 'pt-BR').entries).to all(be_substituted)
    end
  end
end
