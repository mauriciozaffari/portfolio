# frozen_string_literal: true

class Resume
  # Renders the content sections into a Resume::Sheet: metrics, experience,
  # case studies, projects, and skills.
  #
  # Each entry is drawn from a Content::Localized record wrapper, so it knows
  # both the curated record itself and whether it was substituted from another
  # language.
  class Sections
    BULLET = "\u2013 "

    attr_reader :sheet, :helpers

    def initialize(sheet:, helpers:)
      @sheet = sheet
      @helpers = helpers
    end

    def metrics(entries)
      entries.each_with_index do |entry, index|
        record = entry.record
        sheet.divider index
        sheet.mono record[:value], size: Theme::SIZE_3XL, color: Theme::INK, style: :bold
        sheet.tight_gap
        sheet.captioned(record[:label]) do
          sheet.sans record[:context], size: Theme::SIZE_LG, color: Theme::INK_MUTED
        end
        marker entry
      end
    end

    def experience(current_roles, earlier_roles)
      current_roles.each_with_index { |entry, index| role(entry, index:, prominent: true) }

      return if earlier_roles.empty?

      sheet.gap Theme::SPACE_BLOCK
      sheet.label I18n.t('landing.experience.earlier')
      earlier_roles.each_with_index { |entry, index| role(entry, index:, prominent: false) }
    end

    def case_studies(entries)
      entries.each_with_index do |entry, index|
        record = entry.record
        sheet.strong_divider index
        sheet.sans record[:title], size: Theme::SIZE_2XL, color: Theme::INK, style: :bold
        sheet.tight_gap
        sheet.meta [record[:organization], record[:period]]
        sheet.close_gap
        prose entry, size: Theme::SIZE_LG, color: Theme::INK_BODY
        technologies record
        marker entry
      end
    end

    def projects(entries)
      entries.each_with_index do |entry, index|
        record = entry.record
        sheet.divider index
        sheet.formatted project_name(record), size: Theme::SIZE_XL, color: Theme::INK,
                                              font: Theme::MONO, style: :bold
        sheet.tight_gap
        sheet.meta [record[:role], downloads(record)]
        sheet.close_gap
        prose entry, size: Theme::SIZE_LG, color: Theme::INK_BODY
        marker entry
      end
    end

    def skills(skill_groups, education_entries)
      skill_groups.each_with_index do |entry, index|
        record = entry.record
        sheet.divider index
        sheet.label record[:label]
        sheet.tight_gap
        sheet.sans Array(record[:items]).join(Sheet::MIDDOT), size: Theme::SIZE_LG, color: Theme::INK_BODY
        marker entry
      end

      return if education_entries.empty?

      sheet.gap Theme::SPACE_BLOCK
      sheet.label I18n.t('landing.skills.education')
      education_entries.each_with_index { |entry, index| education(entry, index) }
    end

    def prose(entry, size:, color:)
      Prose.blocks(entry.record.html).each_with_index do |block, index|
        sheet.gap Theme::SPACE_CLOSE unless index.zero?
        render_block(block, size:, color:)
      end
    end

    def marker(entry)
      return unless entry&.substituted?

      sheet.close_gap
      sheet.mono "[#{I18n.t("landing.languages.code.#{entry.language}")}]",
                 size: Theme::SIZE_2XS, color: Theme::INK_FAINT, character_spacing: Theme::TRACKING_2XS
    end

    private

    def role(entry, index:, prominent:)
      record = entry.record

      if prominent
        sheet.strong_divider index
        draw_role_heading record, Theme::SIZE_2XL, Theme::SIZE_XL
        prose entry, size: Theme::SIZE_LG, color: Theme::INK_BODY
      else
        sheet.divider index, always: true
        draw_role_heading record, Theme::SIZE_XL, Theme::SIZE_BASE
        prose entry, size: Theme::SIZE_BASE, color: Theme::INK_MUTED
      end

      marker entry
    end

    def draw_role_heading(record, org_size, role_size)
      sheet.sans record[:organization], size: org_size, color: Theme::INK, style: :bold
      sheet.gap Theme::SPACE_TIGHT / 2
      sheet.sans record[:role], size: role_size, color: Theme::INK_BODY
      sheet.tight_gap
      sheet.meta [helpers.role_period(record), record[:location]]
      sheet.close_gap
    end

    def technologies(record)
      items = Array(record[:technologies])
      return if items.empty?

      sheet.close_gap
      sheet.rule
      sheet.tight_gap
      sheet.captioned(I18n.t('landing.work.technologies')) do
        sheet.mono items.join(Sheet::MIDDOT), size: Theme::SIZE_SM, color: Theme::INK_MUTED
      end
    end

    def project_name(record)
      %(<link href="#{record[:url]}">#{Prawn::Text::Formatted::Parser.escape(record[:name].to_s)}</link>)
    end

    def downloads(record)
      total = record[:downloads]
      return if total.blank?

      I18n.t('landing.projects.downloads', total: helpers.number_with_delimiter(total))
    end

    def education(entry, index)
      record = entry.record
      sheet.divider index, always: true

      sheet.row(record[:year].to_s) do |width|
        sheet.sans(record[:credential], size: Theme::SIZE_LG, color: Theme::INK_BODY, width:)
        sheet.gap Theme::SPACE_TIGHT / 2
        sheet.mono record[:institution], size: Theme::SIZE_SM, color: Theme::INK_FAINT
      end

      marker entry
    end

    def render_block(block, size:, color:)
      text = block.text

      case block.kind
      when :heading then sheet.label text
      when :code then sheet.formatted text, size:, color: Theme::INK_MUTED, font: Theme::MONO
      when :item then sheet.formatted BULLET + text, size:, color:
      else sheet.formatted text, size:, color:
      end
    end
  end
end
