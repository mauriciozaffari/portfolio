class ResumeController < ApplicationController
  include Localized

  # No `allow_browser` here, for the reason recorded on ApplicationController: it
  # gates on the User-Agent, and a PDF has no rendering contract to protect. An
  # applicant tracking system fetching the file is not a browser at all, and a
  # 406 would be indistinguishable from the file not existing.
  #
  # This is also why the resume is not folded into LandingController behind a
  # `respond_to`: sharing a controller would put that gate back on this response
  # behind a conditional, and a conditional is a weaker guarantee than a class
  # that simply never declares it.

  # Built per request rather than cached to disk. The container is stateless,
  # the corpus is a few dozen small files, and a cached artifact is a second
  # copy that goes stale — which on a document that cannot be withdrawn once
  # fetched is the failure worth avoiding.
  def show
    resume = Resume.new(page: LandingPage.new(repository: Content.repository, locale: locale))

    send_data resume.pdf, filename: resume.filename, type: Resume::MEDIA_TYPE, disposition: :attachment
  end
end
