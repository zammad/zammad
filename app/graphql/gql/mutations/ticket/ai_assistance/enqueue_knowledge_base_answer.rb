# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::AIAssistance::EnqueueKnowledgeBaseAnswer < BaseMutation
    description 'Trigger generation of a knowledge base answer draft for a ticket'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, loads_pundit_method: :agent_read_access?, description: 'The ticket to generate a knowledge base answer for'

    field :success, Boolean, description: 'Whether the generation job was enqueued successfully.'

    def resolve(ticket:)
      Service::CheckFeatureEnabled.execute(name: 'ai_assistance_kb_answer_from_ticket_generation')
      Service::CheckFeatureEnabled.execute(name: 'ai_provider', custom_error_message: __('AI provider is not configured.'))

      knowledge_base = ::KnowledgeBase.first

      if knowledge_base.blank? || !knowledge_base.visible? || !knowledge_base.categories.exists?
        raise Exceptions::UnprocessableContent, __('Knowledge base is unavailable or not properly configured.')
      end

      editable_categories = ::KnowledgeBase::AccessibleCategories
        .for_user(context.current_user, categories_filter: knowledge_base.categories.root)
        .editor

      if editable_categories.empty?
        raise Exceptions::UnprocessableContent, __('No editable knowledge base categories available.')
      end

      job = TicketAIAssistanceGenerateKnowledgeBaseAnswerJob.perform_later(ticket, context.current_user, knowledge_base.id)

      raise Exceptions::UnprocessableContent, __('Related knowledge base answer creation has already been started for given ticket.') if !job

      { success: true }
    end
  end
end
