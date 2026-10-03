# frozen_string_literal: true

# Renders a LandingPage as Markdown for AI agents, crawlers, and text clients.
#
# A second rendering of the same records, not a second source: every heading,
# role, figure, and link is read back out of Content::Repository. The page and
# this document cannot disagree about a value because neither owns one.
class LandingPageMarkdown
  def initialize(page:, metadata: nil)
    @page = page
    @metadata = metadata || SiteMetadata.new(page:)
  end

  def render
    [
      front_matter,
      masthead,
      impact_section,
      experience_section,
      work_section,
      leadership_section,
      projects_section,
      skills_section,
      contact_section
    ].compact.join("\n\n").concat("\n")
  end

  private

  attr_reader :page, :metadata

  def locale = page.locale

  def profile = page.profile.record

  def heading(key) = I18n.t("landing.#{key}.heading", locale:)

  # YAML front matter, so an agent that fetched this file as a document gets
  # its title and canonical URL without parsing the body.
  def front_matter
    updated = page.updated
    [
      '---',
      "title: #{metadata.title}",
      "description: #{metadata.description}",
      "canonical: #{metadata.canonical_url}",
      ("last-updated: #{updated.iso8601}" if updated),
      "locale: #{locale}",
      '---'
    ].compact.join("\n")
  end

  def masthead
    ["# #{profile[:name]} — #{profile[:headline]}", '', profile.body.to_s.strip].join("\n").strip
  end

  def impact_section
    entries = page.metrics.map do |entry|
      record = entry.record
      "- **#{record[:value]}** — #{record[:label]}. #{record[:context]}"
    end

    section(heading('impact'), entries)
  end

  def experience_section
    roles = page.current_roles + page.earlier_roles
    entries = roles.map do |entry|
      record = entry.record
      period = [record[:start_date],
                record[:end_date] || I18n.t('landing.experience.present', locale:)].join(' – ')

      ["### #{record[:role]}, #{record[:organization]} (#{period})", '', record.body.to_s.strip].join("\n").strip
    end

    section(heading('experience'), entries)
  end

  def work_section
    entries = page.case_studies.map do |entry|
      record = entry.record
      technologies = Array(record[:technologies]).join(', ')

      [
        "### #{record[:title]} — #{record[:organization]} (#{record[:period]})",
        '',
        record.body.to_s.strip,
        '',
        "_#{I18n.t('landing.work.technologies', locale:)}: #{technologies}_"
      ].join("\n").strip
    end

    section(heading('work'), entries)
  end

  def leadership_section
    record = page.leadership.record

    section(record[:title], [record.body.to_s.strip])
  end

  def projects_section
    entries = page.projects.map do |entry|
      record = entry.record
      downloads = record[:downloads]

      [
        "### [#{record[:name]}](#{record[:url]}) — #{record[:role]}",
        (I18n.t('landing.projects.downloads', locale:, total: downloads).to_s if downloads),
        '',
        record.body.to_s.strip
      ].compact.join("\n").strip
    end

    section(heading('projects'), entries)
  end

  def skills_section
    groups = skill_group_lines
    education = education_lines

    entries = []
    entries << groups.join("\n") if groups.any?
    entries << education_section(education) if education.any?

    section(heading('skills'), entries)
  end

  def skill_group_lines
    page.skill_groups.map do |entry|
      record = entry.record
      "- **#{record[:label]}**: #{Array(record[:items]).join(', ')}"
    end
  end

  def education_lines
    page.education.map do |entry|
      record = entry.record
      "- **#{record[:credential]}**, #{record[:institution]} (#{record[:year]})"
    end
  end

  def education_section(education)
    "### #{I18n.t('landing.skills.education', locale:)}\n\n#{education.join("\n")}"
  end

  def contact_section
    links = Array(profile[:links]).map { |link| "- [#{link[:label]}](#{link[:url]})" }
    links << "- #{I18n.t('landing.contact.resume', locale:)}: #{SiteMetadata.origin}#{Resume.path_for(locale)}"

    section(heading('contact'), [links.join("\n")])
  end

  def section(title, entries)
    return nil if entries.empty?

    ["## #{title}", '', entries.join("\n\n")].join("\n")
  end
end
