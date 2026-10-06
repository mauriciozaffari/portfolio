# frozen_string_literal: true

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

  def authored
    send_file Rails.root.join('downloads/mauricio-zaffari-resume.pdf'),
              filename: 'mauricio-zaffari-resume.pdf', type: Resume::MEDIA_TYPE, disposition: :attachment
  end

  # The complete profile stays current without a second stored copy.
  def show
    resume = Resume.new(page: LandingPage.new(repository: Content.repository, locale:))

    send_data resume.pdf, filename: resume.filename, type: Resume::MEDIA_TYPE, disposition: :attachment
  end
end
