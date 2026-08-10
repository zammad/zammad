# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'elasticsearch'

class AI::VectorDB
  SUPPORTED_ES_VERSION_MINIMUM   = '8.11.0'.freeze
  SUPPORTED_ES_VERSION_LESS_THAN = '10.0.0'.freeze

  # An Elasticsearch transport error can carry the whole response body as its message ("[400] {…}").
  # Keep that technical detail in the log and report an actionable message to callers instead.
  ERROR_MESSAGE = __('Semantic search is temporarily unavailable. Please try again later.')

  def config
    @config ||= {
      host:              Setting.get('es_url'),
      user:              Setting.get('es_user'),
      password:          Setting.get('es_password'),
      # Bound connect/read like SearchIndexBackend so a dead or slow Elasticsearch is detected
      # quickly instead of blocking the request thread (e.g. on the availability ping). Same literal
      # open_timeout and the same operator-tunable read timeout env as SearchIndexBackend.
      transport_options: {
        request: {
          open_timeout: 8,
          timeout:      ENV.fetch('ZAMMAD_HTTP_ELASTICSEARCH_READ_TIMEOUT', 180).to_i,
        },
      },
    }
  end

  def client
    @client ||= create_client
  end

  def ping!(only_version: false)
    verify_es_version!
    index_exists if !only_version
  end

  def ping?(only_version: false)
    ping!(only_version:)
    true
  rescue AI::VectorDB::Error
    false
  end

  def migrate(dimensions: 1536)
    return if client.indices.exists?(index: index_name)

    client.indices.create(
      index: index_name,
      body:  {
        mappings: {
          date_detection:    false,
          dynamic_templates: [
            { metadata_dates:   { path_match: 'metadata.*_at', mapping: { type: 'date' } } },
            { metadata_strings: { path_match: 'metadata.*', match_mapping_type: 'string', mapping: { type: 'keyword' } } },
          ],
          properties:        {
            content:     { type: 'text' },
            object_id:   { type: 'keyword' },
            object_name: { type: 'keyword' },
            embedding:   { type: 'dense_vector', dims: dimensions, index: true, similarity: 'cosine' },
            metadata:    { type: 'object', dynamic: true }
          }
        }
      }
    )
  rescue Elastic::Transport::Transport::Error => e
    Rails.logger.error { "AI::VectorDB: #{e.message}" }
    raise AI::VectorDB::Error, __('The Elasticsearch index could not be created')
  end

  def create(content:, object_id:, object_name:, embedding:, metadata: {})
    index_exists

    return if request { client.exists?(index: index_name, id: build_identifier(object_name:, object_id:, content:)) }

    upsert(object_id:, object_name:, content:, embedding:, metadata:) # rubocop:disable Rails/SkipsModelValidations
  end

  def upsert(object_id:, object_name:, content:, embedding:, metadata: {})
    index_exists

    request do
      client.index(
        index: index_name,
        id:    build_identifier(object_name:, object_id:, content:),
        body:  {
          content:     content,
          object_id:   object_id,
          object_name: object_name,
          embedding:   embedding,
          metadata:    metadata
        }
      )
    end
  end

  # Applies many writes in a single _bulk request. `upserts` is a list of
  # { object_id:, object_name:, content:, embedding:, metadata: } (each indexed under its
  # content-addressed id, create-or-replace); `deletes` is a list of document ids to remove.
  def bulk(upserts: [], deletes: [])
    return if upserts.blank? && deletes.blank?

    index_exists

    body = []
    upserts.each do |doc|
      body << { index: { _id: build_identifier(object_name: doc[:object_name], object_id: doc[:object_id], content: doc[:content]) } }
      body << {
        content:     doc[:content],
        object_id:   doc[:object_id],
        object_name: doc[:object_name],
        embedding:   doc[:embedding],
        metadata:    doc[:metadata] || {}
      }
    end
    deletes.each { |id| body << { delete: { _id: id } } }

    response = request { client.bulk(index: index_name, body:) }
    return response if !response.body['errors']

    raise_bulk_error(response)
  end

  # Logs only the items that actually failed (the response lists every operation, success included)
  # and raises.
  def raise_bulk_error(response)
    failed = response.body['items'].select { |item| item.values.any? { |op| op.is_a?(Hash) && op['error'] } }
    Rails.logger.error { "AI::VectorDB: bulk write reported item errors: #{failed}" }
    raise AI::VectorDB::Error, 'The vector index bulk write failed' # rubocop:disable Zammad/DetectTranslatableString
  end

  def update(object_id:, object_name:, content:, embedding:, metadata: {})
    index_exists

    id = build_identifier(object_name:, object_id:, content:)
    request { client.update(index: index_name, id: id, body: { content:, embedding:, metadata: }) }
  end

  # Patches the metadata on every indexed chunk of one document in place (no re-embedding). Used when
  # only metadata changed; the embeddings and chunk set stay as they are.
  def update_metadata(object_id:, object_name:, metadata:)
    index_exists

    response = request do
      client.update_by_query(
        index: index_name,
        body:  {
          query:  { bool: { filter: [{ term: { object_id: } }, { term: { object_name: } }] } },
          script: { source: 'ctx._source.metadata = params.metadata', params: { metadata: } }
        }
      )
    end
    return response.body if !response.body['timed_out'] && response.body['failures'].blank?

    raise_update_by_query_error(response)
  end

  def raise_update_by_query_error(response)
    Rails.logger.error { "AI::VectorDB: metadata update reported failures: #{response.body.slice('timed_out', 'failures')}" }
    raise AI::VectorDB::Error, 'The vector index metadata update failed' # rubocop:disable Zammad/DetectTranslatableString
  end

  def find(object_id:, object_name:, content: nil)
    if !content.nil?
      id = build_identifier(object_name:, object_id:, content:)
      return request { client.get(index: index_name, id: id) }
    end

    response = request do
      client.search(
        index: index_name,
        body:  {
          size:  10_000,
          query: {
            bool: {
              filter: [
                { term: { object_id: } },
                { term: { object_name: } }
              ]
            }
          }
        }
      )
    end

    response.body.dig('hits', 'hits')
  end

  # Ids of all indexed chunks for one document. `_source: false` keeps the payload tiny (just ids).
  def document_ids(object_id:, object_name:)
    response = request do
      client.search(
        index: index_name,
        body:  {
          size:    10_000,
          _source: false,
          query:   {
            bool: {
              filter: [
                { term: { object_id: } },
                { term: { object_name: } }
              ]
            }
          }
        }
      )
    end

    response.body.dig('hits', 'hits').pluck('_id')
  end

  def delete(id:)
    request { client.delete(index: index_name, id:) }
  end

  def destroy(object_id:, object_name:, content: nil)
    if !content.nil?
      id = build_identifier(object_name:, object_id:, content:)
      return if !request { client.exists?(index: index_name, id:) }

      return request { client.delete(index: index_name, id: id) }
    end

    request do
      client.delete_by_query(
        index: index_name,
        body:  {
          query: {
            bool: {
              filter: [
                { term: { object_id: } },
                { term: { object_name: } }
              ]
            }
          }
        }
      )
    end
  end

  def drop
    return if !request { client.indices.exists?(index: index_name) }

    request { client.indices.delete(index: index_name) }
  end

  def knn(embedding:, k: 1, filter: {}) # rubocop:disable Naming/MethodParameterName
    index_exists

    knn = {
      field:          'embedding',
      query_vector:   embedding,
      k:              k,
      num_candidates: k * 10
    }
    ##
    # Restricts the kNN candidates to matching documents (a pre-filter, so the nearest *allowed*
    # neighbours are returned rather than dropping disallowed hits afterwards). Each key becomes a
    # `term` clause for a scalar value or a `terms` clause for an array; multiple keys are combined
    # with AND.
    #
    # Example:
    #   AI::VectorDB.knn(
    #     embedding: [1, 2, 3],
    #     k:         5,
    #     filter:    { object_name: 'KnowledgeBase::Answer::Translation', object_id: [1, 2, 3] }
    #   )
    knn[:filter] = build_filter(filter) if filter.present?

    response = request do
      client.search(
        index: index_name,
        body:  {
          query: {
            knn: knn,
          }
        }
      )
    end

    response.body
  end

  # private class methods

  def build_filter(filter)
    clauses = filter.map do |field, value|
      value.is_a?(Array) ? { terms: { field => value } } : { term: { field => value } }
    end

    clauses.one? ? clauses.first : { bool: { filter: clauses } }
  end

  def index_name
    @index_name ||= "#{Setting.get('es_index')}_#{Rails.env}_ai_embeddings"
  end

  def build_identifier(object_name:, object_id:, content:)
    "#{object_name}-#{object_id}-#{Digest::SHA256.hexdigest(content)}"
  end

  # Map request failures to a user-facing message while keeping the raw details in the log.
  # Faraday errors are rescued alongside transport errors: elastic-transport converts its
  # host-unreachable set (connection failure, read timeout, SSL) into transport errors, but other
  # errors raised in the Faraday stack would otherwise pass through unmapped.
  def request
    yield
  rescue Elastic::Transport::Transport::Error, Faraday::Error => e
    Rails.logger.error { "AI::VectorDB: #{e.class.name}: #{e.message}" }

    raise AI::VectorDB::Error, ERROR_MESSAGE
  end

  def create_client
    client = ::Elasticsearch::Client.new(config)
    client.ping

    client
  rescue Elastic::Transport::Transport::Error => e
    Rails.logger.error { "AI::VectorDB: #{e.message}" }
    raise AI::VectorDB::Error, __('Connection to Elasticsearch Vector DB failed')
  end

  def verify_es_version!
    reported = request { client.info }['version']['number']
    version = Gem::Version.new(reported)
    minimum = Gem::Version.new(SUPPORTED_ES_VERSION_MINIMUM)
    less_than = Gem::Version.new(SUPPORTED_ES_VERSION_LESS_THAN)
    return if version >= minimum && version < less_than

    Rails.logger.error { "AI::VectorDB: Incompatible Elasticsearch version #{reported}" }
    raise AI::VectorDB::Error, __('Incompatible Elasticsearch version')
  end

  def index_exists
    return if request { client.indices.exists?(index: index_name) }

    Rails.logger.error { "AI::VectorDB: Elasticsearch Index #{index_name} does not exist" }
    raise AI::VectorDB::MigrationError, __('Elasticsearch index does not exist')
  end

  class Error < StandardError; end
  class MigrationError < Error; end
end
