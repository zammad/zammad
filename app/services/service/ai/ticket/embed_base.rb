# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Ticket::EmbedBase < Service::Base
  class ContentTooLargeError < StandardError; end

  # @param feature_identifier [String, Symbol, NilClass] the calling feature's identifier, so
  #   the embedding provider is resolved via that feature's routing (see
  #   AI::ProviderConnection.for_embeddings).
  def initialize(ticket:, feature_identifier: nil)
    @ticket             = ticket
    @feature_identifier = feature_identifier
  end

  private

  attr_reader :ticket, :feature_identifier

  def check_content_size!(content)
    tokens = Service::AI::VectorDB::Content::Chunks::Strategy::Base.estimate_tokens(content)
    limit  = embedding_provider.embedding_input_limit

    return if tokens <= limit

    raise ContentTooLargeError, "Content is too large to embed: estimated #{tokens} tokens exceeds model limit of #{limit}."
  end

  def embedding_provider
    @embedding_provider ||= AI::ProviderConnection.for_embeddings(feature_identifier)&.provider_instance ||
                            raise(__('AI provider is not configured.'))
  end
end
