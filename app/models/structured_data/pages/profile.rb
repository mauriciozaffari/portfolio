# frozen_string_literal: true

module StructuredData
  module Pages
    # The JSON-LD for the landing pages, in schema.org's vocabulary.
    #
    # It is built through ruby-structured-data rather than as a hash literal, so
    # a misspelled property is a load-time error rather than a field an agent
    # silently never sees. Every value comes from the curated profile record
    # through SiteMetadata; nothing here invents a fact about a person.
    class Profile
      extend Forwardable

      def initialize(metadata:)
        @metadata = metadata
      end

      attr_reader :metadata

      # The page's identity, as its own entity rather than a graph.
      def person_document = StructuredData.document(person_node)

      # Everything around the person: the site, the page, a breadcrumb, and the
      # questions the records can already answer.
      def graph_document
        StructuredData.document(website_node, profile_page_node, breadcrumb_node, faq_node, graph: true)
      end

      def self.origin = SiteMetadata.origin

      private

      def_delegators :metadata, :profile, :description, :title, :canonical_url, :profile_urls, :locale, :page

      def person_node
        StructuredData.node(
          :Person,
          id: "#{origin}/#person",
          name: profile[:name],
          jobTitle: profile[:headline],
          description:,
          url: canonical_url,
          sameAs: profile_urls
        )
      end

      def website_node
        StructuredData.node(
          :WebSite,
          id: "#{origin}/#website",
          url: "#{origin}/",
          name: profile[:name],
          description:,
          publisher: StructuredData.ref("#{origin}/#person"),
          inLanguage: Content::Schema::LOCALES
        )
      end

      def profile_page_node
        attributes = {
          id: "#{canonical_url}#webpage",
          url: canonical_url,
          name: title,
          description:,
          isPartOf: StructuredData.ref("#{origin}/#website"),
          mainEntity: StructuredData.ref("#{origin}/#person"),
          dateModified: page.updated&.iso8601
        }

        StructuredData.node(:ProfilePage, **attributes.compact)
      end

      def breadcrumb_node
        StructuredData.node(
          :BreadcrumbList,
          id: "#{canonical_url}#breadcrumb",
          itemListElement: [
            StructuredData.node(:ListItem, position: 1, name: 'Home', item: "#{origin}/")
          ]
        )
      end

      # Built from the record fields rather than written as prose: a question an
      # agent asks about this person has an answer the corpus already states.
      # The wording around the answers is chrome and lives in config/locales.
      def faq_node
        StructuredData.node(
          :FAQPage,
          id: "#{canonical_url}#faq",
          mainEntity: questions.map { |question| question_node(question) }
        )
      end

      def question_node(question)
        StructuredData.node(
          :Question,
          name: question[:name],
          acceptedAnswer: StructuredData.node(:Answer, text: question[:text])
        )
      end

      def questions
        [
          { name: I18n.t('metadata.faq.role.question', locale:), text: profile[:headline].to_s },
          { name: I18n.t('metadata.faq.work.question', locale:), text: work_answer },
          { name: I18n.t('metadata.faq.skills.question', locale:), text: skills_answer },
          { name: I18n.t('metadata.faq.contact.question', locale:), text: contact_answer }
        ]
      end

      def work_answer
        [profile[:region], profile[:timezone], profile[:work_mode]].compact_blank.join('. ')
      end

      def skills_answer
        page.skill_groups.map { |entry| entry.record[:label] }.join(', ')
      end

      def contact_answer
        Array(profile[:links]).pluck(:label).join(', ')
      end

      def origin = self.class.origin
    end
  end
end
