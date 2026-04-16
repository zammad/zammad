# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Ticket::KnowledgeBaseAnswersController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def create
    Service::CheckFeatureEnabled.new(name: 'ai_assistance_kb_answer_from_ticket_generation', custom_exception_class: Exceptions::UnprocessableEntity).execute
    Service::CheckFeatureEnabled.new(name: 'ai_provider', custom_error_message: __('AI provider is not configured.')).execute
    authorize!(ticket, :agent_read_access?)

    if knowledge_base.blank? || !knowledge_base.visible? || !knowledge_base.categories.exists?
      return render json: {
        error:         true,
        error_message: __('Knowledge base is unavailable or not properly configured.'),
      }, status: :unprocessable_entity
    end

    editable_categories = KnowledgeBase::AccessibleCategories
      .for_user(current_user, categories_filter: knowledge_base.categories.root)
      .editor

    if editable_categories.empty?
      return render json: {
        error:         true,
        error_message: __('No editable knowledge base categories available.'),
      }, status: :unprocessable_entity
    end

    enqueue_job
  end

  private

  def knowledge_base
    @knowledge_base ||= KnowledgeBase.first
  end

  def ticket
    @ticket ||= Ticket.find(params[:id])
  end

  def enqueue_job
    job = TicketAIAssistanceGenerateKnowledgeBaseAnswerJob.perform_later(ticket, current_user, knowledge_base.id)

    if job
      render json: { status: :ok }
    else
      render json: {
        error:         true,
        error_message: __('Related knowledge base answer creation has already been started for current ticket.'),
      }, status: :unprocessable_entity
    end
  end
end
