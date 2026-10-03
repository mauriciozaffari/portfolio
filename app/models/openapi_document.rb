# frozen_string_literal: true

# The OpenAPI 3.1 description of the read-only API and the MCP server.
#
# Built from the same constants the controllers use, so an endpoint cannot be
# documented that the routing table does not serve, and a response schema cannot
# drift from the serializer that fills it.
class OpenapiDocument
  VERSION = '1.0.0'

  OPERATIONS = {
    'profile' => ['getProfile', 'Return the profile identity: name, headline, region, working mode, and links.'],
    'leadership' => ['getLeadership', 'Return the narrative statement of how this person works.'],
    'experience' => ['listExperience',
                     'Return the employment history as role, organization, dates, and description.'],
    'case-studies' => ['listCaseStudies', 'Return the selected engineering work with its technologies.'],
    'projects' => ['listProjects', 'Return the open-source projects with repository URLs.'],
    'skills' => ['listSkills', 'Return the competency groups and their items.'],
    'education' => ['listEducation', 'Return the credentials and the institutions that granted them.'],
    'metrics' => ['listMetrics', 'Return the impact figures with the context that explains them.']
  }.freeze

  def initialize(origin:)
    @origin = origin
  end

  attr_reader :origin

  def to_h
    {
      'openapi' => '3.1.0',
      'info' => {
        'title' => 'mauricio.zaffari.casa profile API',
        'version' => VERSION,
        'description' => 'Read-only JSON over the curated professional profile. No authentication: this API ' \
                         'serves the same publication-safe content the site renders.\n\n' \
                         '**Versioning.** The major version is the first path segment, so this document ' \
                         'describes `/api/v1` and nothing else. A breaking change — removing a field, ' \
                         'renaming a type, changing an error code — arrives as a new `/api/v2` alongside it ' \
                         'rather than inside it. Additive changes (a new field, a new record type) ship in ' \
                         '`v1` without notice. Before a version is retired its responses carry a `Deprecation` ' \
                         'header with the date the decision was made and a `Sunset` header with the date it ' \
                         'stops answering, both in HTTP-date form, and this document keeps describing it ' \
                         'until it is gone. Nothing is deprecated today.',
        'license' => { 'name' => 'MIT', 'identifier' => 'MIT' }
      },
      'servers' => [{ 'url' => "#{origin}/api/v1", 'description' => 'Production' }],
      'paths' => paths,
      'components' => components
    }
  end

  def paths
    OPERATIONS.to_h do |slug, (operation_id, summary)|
      ["/#{slug}", operation(operation_id, summary)]
    end.merge(
      '/records' => operation('listAllRecords', 'Return every published record of every type.'),
      '/{type}' => type_operation
    )
  end

  def components
    {
      'schemas' => {
        'Record' => Schemas::RECORD,
        'RecordList' => Schemas::RECORD_LIST,
        'ResponseMeta' => Schemas::RESPONSE_META,
        'Error' => Schemas::ERROR
      }
    }
  end

  def locale_parameter
    {
      'name' => 'locale',
      'in' => 'query',
      'required' => false,
      'description' => "Which locale's records to return.",
      'schema' => { 'type' => 'string', 'enum' => Content::Schema::LOCALES, 'default' => Content::Schema::DEFAULT_LOCALE }
    }
  end

  def operation(operation_id, summary)
    {
      'get' => {
        'operationId' => operation_id,
        'summary' => summary,
        'description' => summary,
        'parameters' => [locale_parameter],
        'responses' => {
          '200' => success_response,
          '304' => { 'description' => "The client's cached copy is current." },
          '404' => error_response
        }
      }
    }
  end

  def success_response
    {
      'description' => 'The requested records.',
      'content' => {
        'application/json' => {
          'schema' => {
            'type' => 'object',
            'properties' => {
              'data' => {
                'oneOf' => [
                  { '$ref' => '#/components/schemas/Record' },
                  { 'type' => 'array', 'items' => { '$ref' => '#/components/schemas/Record' } }
                ]
              },
              'meta' => { '$ref' => '#/components/schemas/ResponseMeta' }
            }
          }
        }
      }
    }
  end

  def error_response
    {
      'description' => 'No such record type.',
      'content' => { 'application/json' => { 'schema' => { '$ref' => '#/components/schemas/Error' } } }
    }
  end

  def type_operation
    operation('getRecordsByType', 'Return records by type name; see the named paths for each type.').tap do |entry|
      entry['get']['parameters'] = [
        { 'name' => 'type', 'in' => 'path', 'required' => true,
          'description' => 'Record type to return.',
          'schema' => { 'type' => 'string', 'enum' => RecordSet.type_names } },
        locale_parameter
      ]
    end
  end
end
