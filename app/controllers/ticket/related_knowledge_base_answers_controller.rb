# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Ticket::RelatedKnowledgeBaseAnswersController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  # Synchronously returns the related knowledge base answers for the ticket. When the ticket summary
  # the search relies on is not generated yet, it returns `pending: true` (its generation is
  # requested); the (old stack) client then re-fetches after the
  # 'ticket::related_knowledge_base_answers::ping' event.
  def fetch
    Service::CheckFeatureEnabled.execute(name: 'ai_provider', custom_error_message: __('AI provider is not configured.'))

    authorize!(ticket, :agent_read_access?)
    raise Exceptions::Forbidden if !current_user.permissions?('knowledge_base.*')

    raise Exceptions::UnprocessableContent, __('Knowledge base vector search is not available.') if !Service::AI::VectorDB::Available.execute

    # `embedding_source` is a testing hook (forces the :summary embedding); defaults to :auto.
    result = Service::Ticket::AI::RelatedKnowledgeBaseAnswers
      .with_current_user(current_user)
      .execute(ticket:, embedding_source: params[:embedding_source])

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
