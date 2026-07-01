# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Finds knowledge base answers related to a ticket via vector similarity search. The search itself is
# synchronous, but the ticket embedding it needs is produced asynchronously by the embed job and
# cached. When the embedding is not cached yet we request it and report pending: true so the caller
# retries once the ping arrives.
#
# The `embedding_source` (which the embed job is told to use) defaults to :auto — the content
# embedding, falling back to the summary when the content is too large. It can be forced to :summary
# for testing (the old stack sends it as a request param, settable via App.Config.set); this is a
# testing hook, not a real feature.
# PoC: locale restriction is tracked separately (#1418 / #231).
class Service::Ticket::AI::RelatedKnowledgeBaseAnswers < Service::Base
  requires_current_user!

  RESULT_LIMIT = 3

  attr_reader :ticket, :embedding_source

  def initialize(ticket:, embedding_source: nil)
    @ticket           = ticket
    @embedding_source = embedding_source.to_s == 'summary' ? :summary : :auto
  end

  # Returns:
  #   { answers: [{ translation:, score: }, ...], pending: false } - ordered best-first
  #   { answers: [], pending: false }                              - embedding ready, search found
  #                                                                  nothing to suggest
  #   { answers: nil, pending: true }                              - embedding not ready yet (its
  #                                                                  generation has been requested);
  #                                                                  the job pings on success or
  #                                                                  pushes an error on failure
  def execute
    embedding = Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache.lookup(ticket:, embedding_source:, locale: current_user.locale)
    return { answers: search(embedding), pending: false } if embedding

    TicketAIRelatedKnowledgeBaseAnswersEmbedJob.perform_later(ticket, current_user.locale, embedding_source, current_user:)
    { answers: nil, pending: true }
  end

  # Content-free ping: the embedding is ready, so clients (re)run the synchronous search.
  def self.broadcast_ping(ticket)
    trigger_update(ticket)
  end

  # The embedding could not be produced (a failure, or no embeddable content): tell the clients so
  # they show the error state instead of waiting. The new stack gets the message; the old stack only
  # gets an error flag and shows a generic message.
  def self.broadcast_error(ticket, message)
    trigger_update(ticket, error: message)
  end

  def self.trigger_update(ticket, error: nil)
    Gql::Subscriptions::Ticket::AI::RelatedKnowledgeBaseAnswersUpdates.trigger(
      { error: },
      arguments: { ticket_id: Gql::ZammadSchema.id_from_object(ticket) }
    )

    Sessions.broadcast({
                         event: 'ticket::related_knowledge_base_answers::ping',
                         data:  { ticket_id: ticket.id, error: error.present? }
                       })
  end
  private_class_method :trigger_update

  private

  def search(embedding)
    Service::KnowledgeBase::Answer::SimilaritySearch
      .with_current_user(current_user)
      .execute(embedding:, limit: RESULT_LIMIT, excluded_answer_ids: linked_answer_ids)
  end

  # Answers already linked to the ticket (in any locale) are no suggestion — drop them in the query
  # so the limit still yields up to RESULT_LIMIT fresh ones.
  def linked_answer_ids
    linked_translation_ids = Link
      .list(link_object: 'Ticket', link_object_value: ticket.id)
      .select { |link| link['link_object'] == 'KnowledgeBase::Answer::Translation' }
      .pluck('link_object_value')

    KnowledgeBase::Answer::Translation.where(id: linked_translation_ids).pluck(:answer_id)
  end
end
