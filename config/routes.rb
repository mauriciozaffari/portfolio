# frozen_string_literal: true

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Rails resolves a routing failure through `config.exceptions_app`, which is
  # pointed at the router, so the 404 has to be a route. See ErrorsController.
  match '/404', to: 'errors#not_found', via: :all, as: :not_found
  match '/500', to: 'errors#server_error', via: :all

  # One canonical, static URL per locale — a path prefix rather than a
  # subdomain or content negotiation, so site-metadata has something stable to
  # point hreflang at. Both are `landing#show`; the locale arrives as a route
  # default, which wins over the query string, so `/?locale=pt-BR` cannot serve
  # Portuguese from the English URL.
  root 'landing#show', defaults: { locale: 'en' }
  get 'pt-BR' => 'landing#show', as: :portuguese_root, defaults: { locale: 'pt-BR' }

  # Markdown twins of the two pages. A path rather than content negotiation
  # alone, because the agent that most needs this one is the one that arrives
  # from a search result and sends no Accept header at all.
  get 'index.md' => 'landing#markdown', as: :english_markdown, format: false, defaults: { locale: 'en' }
  get 'pt-BR/index.md' => 'landing#markdown', as: :portuguese_markdown, format: false, defaults: { locale: 'pt-BR' }

  # Served by the application rather than dropped into public/: both documents
  # restate values that live in the content records, and a static copy is a
  # second source that drifts silently.
  #
  # `format: false` drops the `(.:format)` segment, so the dot in each name is a
  # literal — `/robots.txt.json` is a 404, and the path helper cannot generate
  # `/sitemap.xml.xml`.
  get 'robots.txt' => 'site_metadata#robots', as: :robots, format: false
  get 'sitemap.xml' => 'site_metadata#sitemap', as: :sitemap, format: false

  # The discovery documents an AI agent asks for. All are generated from the
  # records rather than committed as files, so an endpoint an agent reads about
  # is one the routing table actually serves.
  get 'llms.txt' => 'site_metadata#llms', as: :llms, format: false
  get 'llms-full.txt' => 'site_metadata#llms_full', as: :llms_full, format: false
  get 'api/llms.txt' => 'site_metadata#api_llms', as: :api_llms, format: false

  # The discoverable spelling of the same guide: `/api` is the URL an agent or a
  # developer guesses, and a footer link to it is what the homepage was missing.
  get 'api' => 'site_metadata#api_llms', as: :api_root, format: false

  # The `.md` twin of any machine-readable document, for the agent that appends
  # `.md` to a URL it already knows. The landing twins are declared above with
  # the pages they belong to; these are the two Ora samples.
  get 'api.md' => 'markdown_twins#api_guide', as: :api_markdown, format: false
  get 'api/llms.txt.md' => 'markdown_twins#api_guide', as: :api_llms_markdown, format: false
  get 'openapi.json.md' => 'markdown_twins#openapi', as: :openapi_markdown, format: false
  get 'agent-skills/llms.txt' => 'site_metadata#skills_llms', as: :skills_llms, format: false

  get '.well-known/ard.json' => 'discovery#ai_catalog', as: :ard_catalog, format: false
  get '.well-known/ai-catalog.json' => 'discovery#ai_catalog', as: :ai_catalog, format: false
  get '.well-known/api-catalog' => 'discovery#api_catalog', as: :api_catalog, format: false
  get '.well-known/agent-card.json' => 'discovery#agent_card', as: :agent_card, format: false
  get '.well-known/agent-skills/index.json' => 'discovery#agent_skills', as: :agent_skills, format: false
  get '.well-known/mcp/server-card.json' => 'discovery#mcp_server_card', as: :mcp_server_card, format: false
  get '.well-known/oauth-protected-resource' => 'discovery#protected_resource', as: :protected_resource, format: false
  get 'agent-skills/:skill.md' => 'discovery#agent_skill', as: :agent_skill, format: false

  # Read-only JSON over the same records the page renders. One resource per
  # record type plus an unsegmented index, each of which accepts ?locale=pt-BR.
  # `scope` keeps v1 in the URL and the helper name without making it a module
  # name, which is what the router would otherwise derive it into.
  namespace :api do
    scope 'v1', as: :v1, defaults: { format: :json } do
      get 'records', to: 'records#index', as: :records
      get 'profile', to: 'records#show', defaults: { type: 'profile' }, as: :profile
      get 'leadership', to: 'records#show', defaults: { type: 'leadership' }, as: :leadership
      get 'experience', to: 'records#show', defaults: { type: 'experience' }, as: :experience
      get 'case-studies', to: 'records#show', defaults: { type: 'case-studies' }, as: :case_studies
      get 'projects', to: 'records#show', defaults: { type: 'projects' }, as: :projects
      get 'skills', to: 'records#show', defaults: { type: 'skills' }, as: :skills
      get 'education', to: 'records#show', defaults: { type: 'education' }, as: :education
      get 'metrics', to: 'records#show', defaults: { type: 'metrics' }, as: :metrics
      get ':type', to: 'records#show', as: :type
    end
  end

  # One MCP endpoint, one transport: Streamable HTTP, as the protocol's current
  # revision defines it. Stateless, so a JSON-RPC message is the whole session.
  get 'mcp' => 'mcp#show', as: :mcp_events, format: false
  post 'mcp' => 'mcp#create', as: :mcp, format: false

  # The OpenAPI description of that API, at the path an agent probes first.
  get 'openapi.json' => 'api/docs#openapi', as: :openapi, format: false

  # Prose an agent reads before it calls anything: how authentication works
  # here (it does not), and how a coding agent should treat this repository.
  get 'auth.md' => 'pages#auth', as: :auth, format: false
  get 'agents.md' => 'pages#agents', as: :agents, format: false

  # The trust pages an agent checks before it recommends a person: who this is,
  # how to reach him, and what is deliberately not published.
  get 'about' => 'pages#about', as: :about, defaults: { locale: 'en' }
  get 'pt-BR/about' => 'pages#about', as: :portuguese_about, defaults: { locale: 'pt-BR' }
  get 'contact' => 'pages#contact', as: :contact, defaults: { locale: 'en' }
  get 'pt-BR/contact' => 'pages#contact', as: :portuguese_contact, defaults: { locale: 'pt-BR' }
  get 'privacy' => 'pages#privacy', as: :privacy, defaults: { locale: 'en' }
  get 'pt-BR/privacy' => 'pages#privacy', as: :portuguese_privacy, defaults: { locale: 'pt-BR' }

  # One resume per locale, alongside the page it is built from. Generated on
  # request from the same records — nothing is written to disk, because the
  # container is stateless and has no writable persistence.
  #
  # The `.pdf` is a literal, as above: `format: false` means `/resume.pdf.json`
  # is a 404 rather than a second URL for the same document.
  get 'resume-short.pdf' => 'resume#authored', as: :authored_resume, format: false, defaults: { locale: 'en' }
  get 'resume.pdf' => 'resume#show', as: :resume, format: false, defaults: { locale: 'en' }
  get 'pt-BR/resume.pdf' => 'resume#show', as: :portuguese_resume, format: false, defaults: { locale: 'pt-BR' }
end
