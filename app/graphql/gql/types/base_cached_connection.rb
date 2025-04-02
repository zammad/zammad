# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class BaseCachedConnection < BaseConnection

    #
    # This class represents a connection with special behaviour. It provides a signature value of the current collection
    #   which changes if the collection state changes. To make use of it, fields with this collection should declare an
    #   `known_collection_signature` argument which can be sent by clients to identify the collection state that is in their
    #   front end cache.
    #
    # If the known_collection_signature value is still valid, the connection will not return `edges` data, to identify that
    #   the cache is still valid.
    #

    edges_nullable(true)

    field :collection_signature, String, null: false do
      description 'Signature that identifies the current collection state. This is always returned, even if the edges data is not because the signature is still the same.'
    end

    def edges
      signature_matches? ? nil : super
    end

    def signature_matches?
      # The collection wrapper object has an accessor for arguments that were declared for the collection field.
      object.arguments[:known_collection_signature] == collection_signature
    end

    # Returns a string that identifies the current collection. It will change whenever the collection content changes.
    def collection_signature
      @collection_signature ||= object.nodes.empty? ? '[]' : Digest::MD5.hexdigest(serialize_collection_metadata)
    end

    def serialize_collection_metadata
      object.nodes.map { |o| "#{o.id}:#{o.updated_at.to_time.to_i}" }.join(',')
    end

  end
end
