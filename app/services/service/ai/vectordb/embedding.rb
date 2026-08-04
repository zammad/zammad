# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  # The single seam for turning content into embedding vectors: a String returns one vector, an
  # Array returns one vector per input. Centralising embedding generation here keeps a future
  # embedding cache (skip re-embedding identical content) out of the indexing callers.
  class Embedding < Service::Base
    attr_reader :input

    def initialize(input:)
      @input = input
    end

    # @return [Array<Numeric>] for a String input; [Array<Array<Numeric>>] for an Array input
    def execute
      return embed_single if !input.is_a?(Array)
      return [] if input.empty?

      connection.record_call do
        vectors = Array(provider.bulk_embed(input:))

        # Fail loudly on a silent partial failure, so no blank vector ever gets indexed. Raised
        # as a ResponseError inside record_call, so the health status reflects it too.
        if vectors.size != input.size || vectors.any?(&:blank?)
          raise AI::Provider::ResponseError, "Embedding provider returned #{vectors.size} usable vectors for #{input.size} inputs"
        end

        vectors
      end
    end

    private

    # A blank scalar vector is the same silent provider failure as a partial bulk result.
    def embed_single
      connection.record_call do
        vector = provider.embed(input:)

        raise AI::Provider::ResponseError, __('Embedding provider returned no usable vector') if vector.blank?

        vector
      end
    end

    # The embedding provider connection; also records the call outcome as its stored health status.
    def connection
      @connection ||= AI::ProviderConnection.for_embeddings || raise(__('AI provider is not configured.'))
    end

    def provider
      @provider ||= connection.provider_instance || raise(__('AI provider is not configured.'))
    end
  end
end
