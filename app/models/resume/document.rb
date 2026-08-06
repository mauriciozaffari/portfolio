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
  # Everything to do with Prawn lives in Resume::Sheet.
  class Document
    BULLET = "\u2013 ".freeze

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
        @sheet ||= Sheet.new(info: info)
      end

      # Flush left and full width, above the gutter grid — the same place the
      # page puts it, for the same reason: it is the document's masthead, not
      # one of its sections.
      def masthead
        profile = page.profile.record

        sheet.sans profile[:name], size: Theme::SIZE_4XL, color: Theme::INK, style: :bold,
          character_spacing: Theme::TRACKING_4XL
        sheet.gap Theme::SPACE_TIGHT
        sheet.sans profile[:headline], size: Theme::SIZE_2XL, color: Theme::INK_BODY

        availability(profile)
        sheet.gap Theme::SPACE_CLOSE
        sheet.accented_rule
        sheet.gap Theme::SPACE_CLOSE
        contact
        sheet.gap Theme::SPACE_BLOCK

        sheet.measured do
          prose page.profile, size: Theme::SIZE_LG, color: Theme::INK_BODY
          marker page.profile
        end
      end

      def substitution_notice
        sheet.gap Theme::SPACE_BLOCK
        sheet.notice I18n.t("landing.substitution.notice")
      end

      def availability(profile)
        items = [ profile[:region], profile[:timezone], profile[:work_mode] ].compact_blank
        return if items.empty?

        sheet.gap Theme::SPACE_CLOSE
        sheet.measured { sheet.mono items.join(Sheet::MIDDOT), size: Theme::SIZE_SM, color: Theme::INK_MUTED }
      end

      # The approved allowlist, and the only contact surface in the file.
      #
      # Shown as the addresses themselves rather than as labelled links: this is
      # a document that gets printed, and a hyperlink whose visible text is the
      # word "LinkedIn" loses its own destination on paper. Every entry is still
      # a live annotation for the readers who never print it.
      def contact
        addresses = Array(page.profile.record[:links]).filter_map { |link| contact_link(link) }
        return if addresses.empty?

        sheet.formatted addresses.join(Sheet::MIDDOT), size: Theme::SIZE_SM, color: Theme::INK, font: Theme::MONO
      end

      def contact_link(link)
        url = link[:url].to_s
        return if url.blank?

        %(<link href="#{url}">#{Resume.display_address(url)}</link>)
      end

      def sections
        section(I18n.t("landing.impact.heading")) { metrics }
        section(I18n.t("landing.experience.heading")) { experience }
        section(I18n.t("landing.work.heading")) { case_studies }
        section(page.leadership.record[:title], entry: page.leadership) { leadership }
        section(I18n.t("landing.projects.heading")) { projects }
        section(I18n.t("landing.skills.heading")) { skills }
      end

      def section(title, entry: nil)
        sheet.section(title) do
          yield
          marker entry if entry
        end
      end

      def metrics
        page.metrics.each_with_index do |entry, index|
          sheet.divider index
          sheet.mono entry.record[:value], size: Theme::SIZE_3XL, color: Theme::INK, style: :bold
          sheet.gap Theme::SPACE_TIGHT
          sheet.label entry.record[:label]
          sheet.gap Theme::SPACE_TIGHT
          sheet.sans entry.record[:context], size: Theme::SIZE_LG, color: Theme::INK_MUTED
          marker entry
        end
      end

      def experience
        page.current_roles.each_with_index { |entry, index| role(entry, index: index, prominent: true) }

        return if page.earlier_roles.empty?

        sheet.gap Theme::SPACE_BLOCK
        sheet.label I18n.t("landing.experience.earlier")
        page.earlier_roles.each_with_index { |entry, index| role(entry, index: index, prominent: false) }
      end

      def role(entry, index:, prominent:)
        if prominent
          sheet.divider index, color: Theme::RULE_STRONG, width: Theme::HAIRLINE_STRONG
        else
          sheet.divider index, always: true
        end

        sheet.sans entry.record[:organization], size: prominent ? Theme::SIZE_2XL : Theme::SIZE_XL,
          color: Theme::INK, style: :bold
        sheet.gap Theme::SPACE_TIGHT / 2
        sheet.sans entry.record[:role], size: prominent ? Theme::SIZE_XL : Theme::SIZE_BASE, color: Theme::INK_BODY
        sheet.gap Theme::SPACE_TIGHT
        sheet.meta [ helpers.role_period(entry.record), entry.record[:location] ]
        sheet.gap Theme::SPACE_CLOSE
        prose entry, size: prominent ? Theme::SIZE_LG : Theme::SIZE_BASE,
          color: prominent ? Theme::INK_BODY : Theme::INK_MUTED
        marker entry
      end

      def case_studies
        page.case_studies.each_with_index do |entry, index|
          sheet.divider index, color: Theme::RULE_STRONG, width: Theme::HAIRLINE_STRONG
          sheet.sans entry.record[:title], size: Theme::SIZE_2XL, color: Theme::INK, style: :bold
          sheet.gap Theme::SPACE_TIGHT
          sheet.meta [ entry.record[:organization], entry.record[:period] ]
          sheet.gap Theme::SPACE_CLOSE
          prose entry, size: Theme::SIZE_LG, color: Theme::INK_BODY
          technologies entry.record
          marker entry
        end
      end

      def technologies(record)
        items = Array(record[:technologies])
        return if items.empty?

        sheet.gap Theme::SPACE_CLOSE
        sheet.rule
        sheet.gap Theme::SPACE_TIGHT
        sheet.label I18n.t("landing.work.technologies")
        sheet.gap Theme::SPACE_TIGHT
        sheet.mono items.join(Sheet::MIDDOT), size: Theme::SIZE_SM, color: Theme::INK_MUTED
      end

      def leadership
        prose page.leadership, size: Theme::SIZE_LG, color: Theme::INK_BODY
      end

      def projects
        page.projects.each_with_index do |entry, index|
          sheet.divider index
          sheet.formatted project_name(entry.record), size: Theme::SIZE_XL, color: Theme::INK,
            font: Theme::MONO, style: :bold
          sheet.gap Theme::SPACE_TIGHT
          sheet.meta [ entry.record[:role], downloads(entry.record) ]
          sheet.gap Theme::SPACE_CLOSE
          prose entry, size: Theme::SIZE_LG, color: Theme::INK_BODY
          marker entry
        end
      end

      def project_name(record)
        %(<link href="#{record[:url]}">#{Prawn::Text::Formatted::Parser.escape(record[:name].to_s)}</link>)
      end

      def downloads(record)
        return if record[:downloads].blank?

        I18n.t("landing.projects.downloads", total: helpers.number_with_delimiter(record[:downloads]))
      end

      def skills
        page.skill_groups.each_with_index do |entry, index|
          sheet.divider index
          sheet.label entry.record[:label]
          sheet.gap Theme::SPACE_TIGHT
          sheet.sans Array(entry.record[:items]).join(Sheet::MIDDOT), size: Theme::SIZE_LG, color: Theme::INK_BODY
          marker entry
        end

        return if page.education.empty?

        sheet.gap Theme::SPACE_BLOCK
        sheet.label I18n.t("landing.skills.education")
        page.education.each_with_index { |entry, index| education(entry, index) }
      end

      def education(entry, index)
        sheet.divider index, always: true

        sheet.row(entry.record[:year].to_s) do |width|
          sheet.sans entry.record[:credential], size: Theme::SIZE_LG, color: Theme::INK_BODY, width: width
          sheet.gap Theme::SPACE_TIGHT / 2
          sheet.mono entry.record[:institution], size: Theme::SIZE_SM, color: Theme::INK_FAINT
        end

        marker entry
      end

      # The last thing in the document, and the reason it is here: a PDF cannot
      # be corrected once it has been downloaded, so it says where the version
      # that can be corrected lives, and how old this one is.
      def colophon
        sheet.gap Theme::SPACE_SECTION
        sheet.keep_together
        sheet.rule Theme::RULE_STRONG, Theme::HAIRLINE_STRONG
        sheet.gap Theme::SPACE_CLOSE

        sheet.mono I18n.t("landing.contact.reviewed", date: helpers.content_date(page.profile.record[:updated])),
          size: Theme::SIZE_SM, color: Theme::INK_FAINT
        sheet.gap Theme::SPACE_TIGHT
        sheet.formatted current_version, size: Theme::SIZE_SM, color: Theme::INK_FAINT, font: Theme::MONO
      end

      def current_version
        url = SiteMetadata.url_for(page.locale)

        I18n.t("resume.current_version", url: %(<link href="#{url}">#{Resume.display_address(url)}</link>))
      end

      def prose(entry, size:, color:)
        Prose.blocks(entry.record.html).each_with_index do |block, index|
          sheet.gap Theme::SPACE_CLOSE unless index.zero?

          case block.kind
          when :heading then sheet.label block.text
          when :code then sheet.formatted block.text, size: size, color: Theme::INK_MUTED, font: Theme::MONO
          when :item then sheet.formatted BULLET + block.text, size: size, color: color
          else sheet.formatted block.text, size: size, color: color
          end
        end
      end

      # The bracketed locale code the page shows on a borrowed record, so a
      # reader meeting an English entry in a Portuguese document is told why
      # rather than left to assume the translation is broken.
      def marker(entry)
        return unless entry&.substituted?

        sheet.gap Theme::SPACE_CLOSE
        sheet.mono "[#{I18n.t("landing.languages.code.#{entry.language}")}]",
          size: Theme::SIZE_2XS, color: Theme::INK_FAINT, character_spacing: Theme::TRACKING_2XS
      end

      # The period formatting and the download delimiter are LandingHelper's
      # rules, and re-implementing either here is exactly the drift this feature
      # exists to prevent.
      def helpers
        ApplicationController.helpers
      end
  end
end
