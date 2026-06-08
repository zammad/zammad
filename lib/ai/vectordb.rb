# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'elasticsearch'

class AI::VectorDB
  SUPPORTED_ES_VERSION_MINIMUM   = '8.11.0'.freeze
  SUPPORTED_ES_VERSION_LESS_THAN = '10.0.0'.freeze

  def config
    @config ||= {
      host:     Setting.get('es_url'),
      user:     Setting.get('es_user'),
      password: Setting.get('es_password')
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
          properties: {
            content:     { type: 'text' },
            object_id:   { type: 'keyword' },
            object_name: { type: 'keyword' },
            embedding:   { type: 'dense_vector', dims: dimensions, index: true, similarity: 'l2_norm' },
            metadata:    { type: 'object', enabled: false }
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

    return if client.exists?(index: index_name, id: build_identifier(object_name:, object_id:))

    upsert(object_id:, object_name:, content:, embedding:, metadata:) # rubocop:disable Rails/SkipsModelValidations
  end

  def upsert(object_id:, object_name:, content:, embedding:, metadata: {})
    index_exists

    client.index(
      index: index_name,
      id:    build_identifier(object_name:, object_id:),
      body:  {
        content:     content,
        object_id:   object_id,
        object_name: object_name,
        embedding:   embedding,
        metadata:    metadata
      }
    )
  end

  def update(object_id:, object_name:, content:, embedding:, metadata: {})
    index_exists

    id = build_identifier(object_name:, object_id:)
    client.update(index: index_name, id: id, body: { content:, embedding:, metadata: })
  end

  def find(object_id:, object_name:)
    id = build_identifier(object_name:, object_id:)

    client.get(index: index_name, id: id)
  end

  def destroy(object_id:, object_name:)
    id = build_identifier(object_name:, object_id:)

    return if !client.exists?(index: index_name, id:)

    client.delete(index: index_name, id: id)
  end

  def drop
    return if !client.indices.exists?(index: index_name)

    client.indices.delete(index: index_name)
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
    # Only one-dimensional filter with a single key-value (field name, value
    # string) pair is supported.
    #
    # Example:
    #   AI::VectorDB::Elasticsearch.nearest_neighbours(
    #     embedding: [1, 2, 3],
    #     limit: 5,
    #     filter: { object_name: 'Ticket' }
    #   )
    knn[:filter] = { term: filter } if filter.present?

    client.search(
      index: index_name,
      body:  {
        query: {
          knn: knn,
        }
      }
    ).body
  end

  # private class methods

  def index_name
    @index_name ||= "#{Setting.get('es_index')}_#{Rails.env}_ai_embeddings"
  end

  def build_identifier(object_name:, object_id:)
    "#{object_name}-#{object_id}"
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
    version = Gem::Version.new(client.info['version']['number'])
    minimum = Gem::Version.new(SUPPORTED_ES_VERSION_MINIMUM)
    less_than = Gem::Version.new(SUPPORTED_ES_VERSION_LESS_THAN)
    return if version >= minimum && version < less_than

    Rails.logger.error { "AI::VectorDB: Incompatible Elasticsearch version #{client.info['version']['number']}" }
    raise AI::VectorDB::Error, __('Incompatible Elasticsearch version')
  end

  def index_exists
    return if client.indices.exists?(index: index_name)

    Rails.logger.error { "AI::VectorDB: Elasticsearch Index #{index_name} does not exist" }
    raise AI::VectorDB::MigrationError, __('Elasticsearch index does not exist')
  end

  class Error < StandardError; end
  class MigrationError < Error; end
end
