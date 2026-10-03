# frozen_string_literal: true

# The read-only JSON API over the curated records.
#
# Public by design: it needs no key and no account, which is what makes it
# usable by an agent that cannot complete a signup flow. Errors are JSON in
# one shape, so an agent never has to parse an HTML error page to find out what
# went wrong.
#
# The class carries no version in its name: v1 is a URL segment, and Reek
# rejects a module whose name is an abbreviation with a digit in it. The scope
# in config/routes.rb is what keeps /api/v1 in the path.
module Api
  class RecordsController < ApplicationController
    include Localized

    def index
      render_json(
        {
          'data' => RecordSet.new(locale:).all,
          'meta' => { 'locale' => locale, 'types' => RecordSet.type_names }
        },
        etag: cache_key('all')
      )
    end

    def show
      type = params[:type].to_s

      unless RecordSet.known_type?(type)
        return render_error(code: 'not_found', message: "No such record type: #{type}", status: :not_found)
      end

      render_json(
        { 'data' => RecordSet.new(locale:).serialize(type), 'meta' => { 'type' => type, 'locale' => locale } },
        etag: cache_key(type)
      )
    end

    private

    def cache_key(type) = "#{type}-#{locale}-#{Content.repository.records.size}"

    def render_json(payload, etag:)
      headers = response.headers
      headers['Cache-Control'] = 'public, max-age=300'
      headers['Vary'] = 'Accept'

      body = JSON.pretty_generate(payload)

      return head :not_modified if request.headers['If-None-Match'] == %("#{etag}")

      headers['ETag'] = %("#{etag}")
      render plain: body, content_type: 'application/json; charset=utf-8'
    end

    # One shape for every error, so an agent never has to parse an HTML page to
    # find out what went wrong. `details` is always the record vocabulary, the
    # only thing a caller can do about a type it got wrong.
    def render_error(code:, message:, status:)
      error = { 'code' => code, 'message' => message, 'details' => RecordSet.type_names }
      render plain: JSON.pretty_generate('error' => error), status:,
             content_type: 'application/json; charset=utf-8'
    end
  end
end
