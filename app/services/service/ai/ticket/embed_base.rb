# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Ticket::EmbedBase < Service::Base
  class ContentTooLargeError < StandardError; end

  def initialize(ticket:)
    @ticket = ticket
  end

  private

  attr_reader :ticket

  def check_content_size!(content)
    tokens = Service::AI::VectorDB::Content::Chunks::Strategy::Base.estimate_tokens(content)
    limit  = embedding_provider.embedding_input_limit

    return if tokens <= limit

    raise ContentTooLargeError, "Content is too large to embed: estimated #{tokens} tokens exceeds model limit of #{limit}."
  end

  def embedding_provider
    @embedding_provider ||= AI::ProviderConnection.for_embeddings&.provider_instance ||
                            raise(__('AI provider is not configured.'))
  end
end
