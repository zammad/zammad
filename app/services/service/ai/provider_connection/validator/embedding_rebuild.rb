# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::ProviderConnection::Validator
  # Stops a save that would leave the vector index holding vectors nothing queries anymore, until the
  # admin has said yes to it. Not because the save is invalid - it is the change the admin asked for -
  # but because it spends their time, tokens and API calls, and they should know before it starts (see
  # Service::Ticket::Update::Validator for the same shape).
  #
  # Raised at the caller of the save rather than in the model on purpose: `rails console` and the
  # API change the same records, and there the change simply takes effect - nobody is standing there
  # to confirm anything. The rebuild itself is decided by Service::AI::VectorDB::Reconcile, wherever
  # the change came from.
  class EmbeddingRebuild < Service::Base
    # What the client sends back to say the admin has seen it.
    IDENTIFIER = 'embedding_rebuild'.freeze

    attr_reader :after

    # @param after [Hash, NilClass] the embedding configuration the save would leave semantic search on
    def initialize(after:)
      @after = after
    end

    def execute
      # What the index holds, not what is configured now: the two are compared here for exactly the
      # question a rebuild is queued under (Service::AI::VectorDB::Reconcile), so the warning means
      # "this save invalidates what the index holds" regardless of whether the AI provider or the
      # vector database happen to be switched on at the moment of the save - a change made while
      # either is off still warns, and the later automatic rebuild on re-enable is thereby already
      # confirmed.
      #
      # Nothing built means nothing re-created, so there is nothing to warn about - the first build is
      # what switching the vector database on pays for.
      indexed = Service::AI::VectorDB::Embedding::Configuration.indexed
      return if indexed.nil?

      return if !Service::AI::VectorDB::Embedding::Configuration.changed?(indexed, after)

      raise Error
    end

    class Error < StandardError
      def initialize
        super(__('This change requires the knowledge base to be indexed again.'))
      end

      def skip_validator
        IDENTIFIER
      end
    end
  end
end
