# frozen_string_literal: true

module Content
  # The publication gate, run over the two surfaces that are equally public: the
  # Markdown in the repository, and the HTML the application renders.
  #
  # A rule that never fires is worse than no rule, because it manufactures
  # confidence. Every rule below is exercised against a deliberately unsafe
  # fixture in spec/fixtures, and that spec fails if a rule is added here
  # without one.
  class SafetyScanner
    # The contact addresses the SPEC's allowlist admits: the primary public
    # address (also this repository's commit identity), and the forwarding
    # alias on the owner's own domain. Both are deliberately public.
    ALLOWED = ['mauriciozaffari@gmail.com', 'mauricio@zaffari.casa'].freeze

    Rule = Data.define(:name, :pattern)

    # Patterns use non-capturing groups throughout, because a capture would
    # change what String#scan hands back for the allowlist check below.
    RULES = [
      Rule.new(name: 'email address',
               pattern: /[A-Za-z0-9._%+-]+@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z]{2,})+/),

      Rule.new(name: 'phone number, international',
               pattern: /\+\d{1,3}[\s.-]?\(?\d{2,3}\)?[\s.-]?\d{4,5}[\s.-]?\d{4}\b/),
      Rule.new(name: 'phone number, area code', pattern: /\(\d{2}\)\s?\d{4,5}[\s-]?\d{4}\b/),
      Rule.new(name: 'phone number, Brazilian mobile', pattern: /\b\d{5}-\d{4}\b/),
      Rule.new(name: 'phone number, Brazilian landline', pattern: /\b\d{4}-\d{4}\b/),

      Rule.new(name: 'CPF', pattern: /\b\d{3}\.\d{3}\.\d{3}-\d{2}\b/),
      Rule.new(name: 'CNPJ', pattern: %r{\b\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}\b}),
      Rule.new(name: 'RG', pattern: /\b\d{1,2}\.\d{3}\.\d{3}-[\dXx]\b/),
      Rule.new(name: 'passport number', pattern: /\b[A-Z]{2}\d{6}\b/),
      Rule.new(name: 'unpunctuated document number', pattern: /\b\d{8,}\b/),

      Rule.new(name: 'postal code', pattern: /\b\d{5}-\d{3}\b/),
      Rule.new(name: 'street address', pattern: /\b(?:Rua|Avenida|Av\.|Alameda|Travessa)\s+[A-ZÀ-Þ]/),

      Rule.new(name: 'API or secret key', pattern: /\b(?:api|secret|access|private)[\s_-]?keys?\b/i),
      Rule.new(name: 'password', pattern: /\bpasswords?\b/i),
      Rule.new(name: 'bearer token', pattern: %r{\bbearer\s+[A-Za-z0-9\-._~+/]{16,}={0,2}}i),
      Rule.new(name: 'JSON web token', pattern: /\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]+/),
      Rule.new(name: 'private key block', pattern: /-----BEGIN [A-Z ]*PRIVATE KEY-----/),

      Rule.new(name: 'salary or remuneration', pattern: /\b(?:salary|salaries|remuneration)\b/i),
      Rule.new(name: 'pay or day rate', pattern: /\b(?:pay|day)[\s_-]rate\b/i),
      Rule.new(name: 'share option', pattern: /\bshare options?\b/i),
      Rule.new(name: 'option grant', pattern: /\boption grants?\b/i),
      Rule.new(name: 'equity', pattern: /\bequity\b/i)
    ].freeze

    # Propshaft fingerprints every asset URL with the first eight hex characters
    # of a SHA1 over the compiled file. Roughly one digest in forty comes out as
    # eight digits and would trip the unpunctuated-document-number rule on a
    # page holding no personal data at all. A digest is derived from a file this
    # application compiled, so it cannot carry curated content: drop it, and
    # leave every other byte of the markup alone.
    ASSET_DIGEST = %r{(?<=/assets/)([\w./-]*?)-[0-9a-f]{8}(?=\.)}

    def scan(text, source:)
      text.each_line.with_index(1).flat_map { |line, number| findings_for(line, number, source) }
    end

    def scan_html(html, source:)
      scan(html.gsub(ASSET_DIGEST, '\1'), source:)
    end

    def scan_tree(root)
      root = Pathname(root)

      Content.files_under(root).flat_map do |path|
        scan_file(path, source: root.basename.join(path.relative_path_from(root)).to_s)
      end
    end

    def scan_file(path, source:)
      text = path.read
      return [Finding.new(reason: 'is not UTF-8 text', source:, line: 1)] unless text.valid_encoding?

      scan(text, source:)
    end

    private

    def findings_for(line, number, source)
      offended = RULES.select { |rule| offends?(line, rule) }
      offended.map { |rule| Finding.new(reason: rule.name, source:, line: number) }
    end

    def offends?(line, rule)
      line.scan(rule.pattern).any? { |match| !allowed?(match) }
    end

    def allowed?(match)
      ALLOWED.any? { |value| value.casecmp?(match) }
    end
  end
end
