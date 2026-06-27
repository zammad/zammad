# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  # The single seam for turning content into embedding vectors: a String returns one vector, an
  # Array returns one vector per input. Centralising embedding generation here keeps a future
  # embedding cache (skip re-embedding identical content) out of the indexing callers.
  class Embedding < Service::Base
    attr_reader :input

    # @param input [String, Array<String>] content to embed
    def initialize(input:)
      @input = input
    end

    # @return [Array<Numeric>] for a String input; [Array<Array<Numeric>>] for an Array input
    def execute
      return provider.embed(input:) if !input.is_a?(Array)
      return [] if input.empty?

      vectors = Array(provider.bulk_embed(input:))

      # Fail loudly on a silent partial failure, so no blank vector ever gets indexed.
      if vectors.size != input.size || vectors.any?(&:blank?)
        raise "Embedding provider returned #{vectors.size} usable vectors for #{input.size} inputs"
      end

      vectors
    end

    private

    def provider
      @provider ||= begin
        current = AI::Provider.current
        raise __('AI provider is not configured.') if current.nil?

        current.new
      end
    end
  end
end
