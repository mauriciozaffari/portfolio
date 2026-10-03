# frozen_string_literal: true

class Resume
  # What this document says, and in what order.
  #
  # Every fact arrives through LandingPage, which is the same object the HTML
  # view reads. Nothing is restated: this file decides where a value sits and in
  # which face, and if it wanted to say something the corpus does not, it would
  # have nowhere to get it from. That is the mitigation for the SPEC's accepted
  # trade — the layout diverges from the page, and only the layout can.
  #
  # The section order, the entry order and the substitution marks are
  # LandingPage's, so a record added to data/ appears in both surfaces in the
  # same place with no second ordering rule to keep in sync.
  #
  # Everything to do with Prawn lives in Resume::Sheet, and how each section's
  # entries are laid out lives in Resume::Sections.
  class Document
    attr_reader :page, :info

    def initialize(page:, info:)
      @page = page
      @info = info
    end

    def render
      masthead
      substitution_notice if page.substituted?
      sections
      colophon

      sheet.render
    end

    private

    def sheet
      @sheet ||= Sheet.new(info:)
    end

    def layout
      @layout ||= Sections.new(sheet:, helpers: ApplicationController.helpers)
    end

    # Flush left and full width, above the gutter grid — the same place the
    # page puts it, for the same reason: it is the document's masthead, not
    # one of its sections.
    def masthead
      entry = page.profile
      profile = entry.record

      sheet.sans profile[:name], size: Theme::SIZE_4XL, color: Theme::INK, style: :bold,
                                 character_spacing: Theme::TRACKING_4XL
      sheet.tight_gap
      sheet.sans profile[:headline], size: Theme::SIZE_2XL, color: Theme::INK_BODY

      availability(profile)
      rule_and_contact(profile)

      sheet.measured do
        layout.prose entry, size: Theme::SIZE_LG, color: Theme::INK_BODY
        layout.marker entry
      end
    end

    def rule_and_contact(profile)
      sheet.accented_rule_with_room
      contact(profile)
      sheet.gap Theme::SPACE_BLOCK
    end

    def substitution_notice
      sheet.gap Theme::SPACE_BLOCK
      sheet.notice I18n.t('landing.substitution.notice')
    end

    def availability(profile)
      items = [profile[:region], profile[:timezone], profile[:work_mode]].compact_blank
      return if items.empty?

      sheet.close_gap
      sheet.measured { sheet.mono items.join(Sheet::MIDDOT), size: Theme::SIZE_SM, color: Theme::INK_MUTED }
    end

    # The approved allowlist, and the only contact surface in the file.
    #
    # Shown as the addresses themselves rather than as labelled links: this is
    # a document that gets printed, and a hyperlink whose visible text is the
    # word "LinkedIn" loses its own destination on paper. Every entry is still
    # a live annotation for the readers who never print it.
    def contact(profile)
      addresses = Array(profile[:links]).pluck(:url).compact_blank.map { |url| contact_link(url) }
      return if addresses.empty?

      sheet.formatted addresses.join(Sheet::MIDDOT), size: Theme::SIZE_SM, color: Theme::INK, font: Theme::MONO
    end

    def contact_link(url)
      %(<link href="#{url}">#{Resume.display_address(url)}</link>)
    end

    # The same six sections, in the same order, as the page.
    def sections
      impact
      experience
      work
      leadership
      projects
      skills
    end

    def impact
      section(I18n.t('landing.impact.heading')) { layout.metrics(page.metrics) }
    end

    def experience
      section(I18n.t('landing.experience.heading')) { layout.experience(page.current_roles, page.earlier_roles) }
    end

    def work
      section(I18n.t('landing.work.heading')) { layout.case_studies(page.case_studies) }
    end

    def leadership
      entry = page.leadership

      section(entry.record[:title], entry:) do
        layout.prose entry, size: Theme::SIZE_LG, color: Theme::INK_BODY
      end
    end

    def projects
      section(I18n.t('landing.projects.heading')) { layout.projects(page.projects) }
    end

    def skills
      section(I18n.t('landing.skills.heading')) { layout.skills(page.skill_groups, page.education) }
    end

    def section(title, entry: nil)
      sheet.section(title) do
        yield
        layout.marker entry
      end
    end

    # The last thing in the document, and the reason it is here: a PDF cannot
    # be corrected once it has been downloaded, so it says where the version
    # that can be corrected lives, and how old this one is.
    def colophon
      sheet.gap Theme::SPACE_SECTION
      sheet.keep_together
      sheet.rule Theme::RULE_STRONG, Theme::HAIRLINE_STRONG
      sheet.close_gap

      sheet.mono I18n.t('landing.contact.reviewed', date: reviewed_on),
                 size: Theme::SIZE_SM, color: Theme::INK_FAINT
      sheet.tight_gap
      sheet.formatted current_version, size: Theme::SIZE_SM, color: Theme::INK_FAINT, font: Theme::MONO
    end

    def reviewed_on
      ApplicationController.helpers.content_date(page.profile.record[:updated])
    end

    def current_version
      url = SiteMetadata.url_for(page.locale)

      I18n.t('resume.current_version', url: %(<link href="#{url}">#{Resume.display_address(url)}</link>))
    end
  end
end
