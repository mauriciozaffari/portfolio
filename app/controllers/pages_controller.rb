# frozen_string_literal: true

# The prose pages around the profile: who this is, how to make contact, what is
# deliberately not published, and the two walkthroughs an agent reads before it
# calls anything.
#
# The about and contact pages are assembled from the same records the landing
# page renders, so nothing on them can contradict the profile. Privacy and the
# agent walkthroughs are policy prose, which has no record to come from and
# lives in config/locales with the rest of the chrome.
class PagesController < ApplicationController
  include Localized

  def about
    build
    render :show
  end

  def contact
    build
    render :show
  end

  def privacy
    build
    render :show
  end

  # The WorkOS-shaped walkthrough for an agent that goes looking for
  # credentials. Here the honest answer is that there are none.
  def auth
    build
    render formats: :text, content_type: 'text/markdown; charset=utf-8'
  end

  # How a coding agent should treat this repository, served where an agent looks
  # even before it has a checkout; AGENTS.md is the source it restates.
  def agents
    build
    render formats: :text, content_type: 'text/markdown; charset=utf-8'
  end

  private

  # The canonical URL of this page, so /about does not claim to be the
  # homepage. Every route here is static, so the request path is the answer.
  def build
    page = LandingPage.new(repository: Content.repository, locale:)
    @page = page
    @metadata = SiteMetadata.new(page:, path: request.path)
  end
end
