require "rails_helper"

# These headers are the deployed artifact's only defence that does not depend on
# the proxy in front of it, so they are set in the Rails app (config/application.rb
# and config/initializers/content_security_policy.rb) rather than in
# config/deploy.yml, and asserted here so that a config change cannot drop one
# silently.
RSpec.describe "Security headers", type: :request do
  subject(:headers) { response.headers }

  shared_examples "a hardened response" do
    it "refuses content-type sniffing" do
      expect(headers["X-Content-Type-Options"]).to eq("nosniff")
    end

    it "leaks no path to a cross-origin target" do
      expect(headers["Referrer-Policy"]).to eq("strict-origin-when-cross-origin")
    end

    it "cannot be framed" do
      expect(headers["X-Frame-Options"]).to eq("DENY")
      expect(headers["Content-Security-Policy"]).to include("frame-ancestors 'none'")
    end

    it "denies the browser features the site does not use" do
      expect(headers["Permissions-Policy"]).to include("camera=()", "geolocation=()", "microphone=()")
    end

    it "names every denied feature with an empty allowlist and nothing else" do
      expect(headers["Permissions-Policy"].split(", ")).to all(end_with("=()"))
    end

    it "sends a Permissions-Policy rather than the superseded Feature-Policy" do
      expect(headers).to have_key("Permissions-Policy")
      expect(headers).not_to have_key("Feature-Policy")
    end

    it "sets the remaining Rails defaults it relies on" do
      expect(headers["X-Permitted-Cross-Domain-Policies"]).to eq("none")
      expect(headers["X-XSS-Protection"]).to eq("0")
    end
  end

  shared_examples "a page that blocks inline script" do
    let(:policy) { headers["Content-Security-Policy"] }

    it "denies everything it does not explicitly allow" do
      expect(policy).to include("default-src 'none'")
    end

    it "blocks script outright, inline or otherwise" do
      expect(policy).to include("script-src 'none'")
    end

    it "permits no unsafe source anywhere in the policy" do
      expect(policy).not_to include("unsafe-inline")
      expect(policy).not_to include("unsafe-eval")
      expect(policy).not_to include("unsafe-hashes")
    end

    it "allows only first-party styles and images" do
      expect(policy).to include("style-src 'self'", "img-src 'self'")
    end

    it "allows no plugin, no base tag, and no form target" do
      expect(policy).to include("object-src 'none'", "base-uri 'none'", "form-action 'none'")
    end
  end

  # The policy above is only honest while the page actually obeys it. These two
  # assert the page against its own policy, so adding a script tag or a CDN font
  # fails the suite here rather than in a browser console after a deploy.
  shared_examples "a page the policy does not break" do
    let(:document) { Nokogiri::HTML5(response.body) }

    it "loads no script the policy would block" do
      expect(document.css("script")).to be_empty
    end

    it "carries no inline style attribute or style block" do
      expect(document.css("style")).to be_empty
      expect(document.css("[style]")).to be_empty
    end

    it "loads every subresource from this origin" do
      sources = document.css("link[href], img[src]").map { |node| node["href"] || node["src"] }

      expect(sources).not_to be_empty
      expect(sources).to all(start_with("/"))
    end
  end

  describe "GET /" do
    before { get root_path }

    include_examples "a hardened response"
    include_examples "a page that blocks inline script"
    include_examples "a page the policy does not break"
  end

  describe "GET /pt-BR" do
    before { get portuguese_root_path }

    include_examples "a hardened response"
    include_examples "a page that blocks inline script"
    include_examples "a page the policy does not break"
  end

  # The health check is Rails' own controller, not this application's, so it is
  # asserted separately: it must stay reachable and it must not be handed a
  # weaker policy to accommodate the inline style attribute it renders.
  describe "GET /up" do
    before { get rails_health_check_path }

    include_examples "a hardened response"
    include_examples "a page that blocks inline script"

    it "still answers 200 for the proxy healthcheck" do
      expect(response).to have_http_status(:ok)
    end
  end

  # HSTS is the one header that cannot be asserted from a request above, because
  # enabling force_ssl in the test environment would redirect every other spec in
  # the suite. config/environments/production.rb is therefore evaluated against a
  # throwaway configuration, and the options it sets are run through the real
  # ActionDispatch::SSL so that what is asserted is the header a browser receives
  # rather than the hash a human wrote.
  describe "the production SSL configuration" do
    let(:production) do
      configuration = Rails::Application::Configuration.new(Rails.root)
      allow(Rails.application).to receive(:config).and_return(configuration)
      load Rails.root.join("config/environments/production.rb").to_s
      configuration
    end

    let(:strict_transport_security) do
      ssl = ActionDispatch::SSL.new(->(_env) { [ 200, {}, [ "" ] ] }, **production.ssl_options)
      _status, headers, _body = ssl.call(Rack::MockRequest.env_for("https://zaffari.casa/"))
      headers["strict-transport-security"]
    end

    it "redirects HTTP to HTTPS" do
      expect(production.force_ssl).to be(true)
    end

    it "trusts the proxy's TLS termination, which is what keeps /up off the redirect path" do
      expect(production.assume_ssl).to be(true)
    end

    it "commits to HTTPS for two years, subdomains included" do
      expect(strict_transport_security).to eq("max-age=#{2.years.to_i}; includeSubDomains")
    end

    it "does not preload, which would be a one-way door taken before the first deploy" do
      expect(strict_transport_security).not_to include("preload")
    end
  end
end
