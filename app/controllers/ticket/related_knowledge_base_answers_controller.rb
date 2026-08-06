# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Ticket::RelatedKnowledgeBaseAnswersController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  # Synchronously returns the related knowledge base answers for the ticket. When the ticket summary
  # the search relies on is not generated yet, it returns `pending: true` (its generation is
  # requested); the (old stack) client then re-fetches after the
  # 'ticket::related_knowledge_base_answers::ping' event.
  #
  # No knowledge base permission is required: which answers may be suggested is decided by the
  # search itself (KnowledgeBase::Answer.visible_to_user), so agents without knowledge base access
  # are suggested published answers only, which they can read on the public help site.
  def fetch
    Service::CheckFeatureEnabled.execute(name: 'ai_provider', custom_error_message: __('AI provider is not configured.'))

    authorize!(ticket, :agent_read_access?)

    raise Exceptions::UnprocessableContent, __('Knowledge base vector search is not available.') if !Service::AI::VectorDB::Available.execute

    # `embedding_source` is a testing hook (forces the :summary embedding); defaults to :auto.
    result = Service::Ticket::AI::RelatedKnowledgeBaseAnswers
      .with_current_user(current_user)
      .execute(ticket:, embedding_source: params[:embedding_source], include_drafts_and_archived:, include_linked_answers:)

    return render json: { result: { pending: true } } if result[:pending]

    translations = result[:answers].pluck(:translation)

    render json: {
      result: result_for(result[:answers], translations),
      assets: assets_for(translations),
    }
  end

  private

  def ticket
    @ticket ||= Ticket.find(params[:id])
  end

  # Drafts and archived answers are no suggestion for working on the ticket, but they do count when
  # checking whether an answer already covers its topic (the answer generation dialog asks for them).
  def include_drafts_and_archived
    ActiveModel::Type::Boolean.new.cast(params[:include_drafts_and_archived]) || false
  end

  # Same for answers already linked to the ticket: the sidebar lists them on its own and leaves them
  # out of the suggestions, the answer generation dialog wants to see them among the coverage.
  def include_linked_answers
    ActiveModel::Type::Boolean.new.cast(params[:include_linked_answers]) || false
  end

  def result_for(answers, translations)
    {
      pending:                false,
      answer_translation_ids: translations.map(&:id),
      scores:                 answers.to_h { |answer| [answer[:translation].id.to_s, answer[:score]] },
      excerpts:               translations.to_h { |translation| [translation.id.to_s, translation.content.body_excerpt] },
    }
  end

  def assets_for(translations)
    translations.each_with_object({}) { |translation, assets| translation.assets(assets) }
  end
end
