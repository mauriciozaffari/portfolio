# frozen_string_literal: true

class OpenapiDocument
  # The component schemas the responses reference, as data. They are constants
  # because they never vary with the request; the document that carries them is
  # built per call so the origin can.
  module Schemas
    RECORD = {
      'type' => 'object',
      'additionalProperties' => true,
      'required' => %w[id type locale],
      'properties' => {
        'id' => { 'type' => 'string' },
        'type' => { 'type' => 'string', 'enum' => Content::Schema::NAMES + RecordSet.type_names },
        'body' => { 'type' => 'string', 'description' => "The record's prose, as Markdown." },
        'updated' => { 'type' => 'string', 'format' => 'date' },
        'locale' => { 'type' => 'string', 'enum' => Content::Schema::LOCALES }
      }
    }.freeze

    RECORD_LIST = {
      'type' => 'object',
      'required' => %w[data meta],
      'properties' => {
        'data' => { 'type' => 'array', 'items' => { '$ref' => '#/components/schemas/Record' } },
        'meta' => { '$ref' => '#/components/schemas/ResponseMeta' }
      }
    }.freeze

    RESPONSE_META = {
      'type' => 'object',
      'properties' => {
        'locale' => { 'type' => 'string', 'enum' => Content::Schema::LOCALES },
        'type' => { 'type' => 'string', 'enum' => RecordSet.type_names }
      }
    }.freeze

    ERROR = {
      'type' => 'object',
      'required' => %w[error],
      'properties' => {
        'error' => {
          'type' => 'object',
          'required' => %w[code message],
          'properties' => {
            'code' => { 'type' => 'string' },
            'message' => { 'type' => 'string' },
            'details' => { 'type' => 'array', 'items' => { 'type' => 'string' } }
          }
        }
      }
    }.freeze
  end
end
