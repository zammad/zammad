# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class TicketAIAssistanceGenerateKnowledgeBaseAnswerJob < AIJob
  include HasActiveJobLock

  EXISTING_ACTIVE_JOB_LOCK_BEHAVIOUR = :dismiss_running

  # job-class/ticket-id/last-article-timestamp/knowledge-base-id
  def lock_key
    "#{self.class.name}/#{arguments[0].id}/#{arguments[0].articles.without_system_notifications.last&.created_at}/#{arguments[2]}"
  end

  def perform(ticket, current_user, knowledge_base_id)
    Service::Ticket::AIAssistance::CreateKnowledgeBaseAnswer.new(
      current_user:,
      ticket:,
      knowledge_base_id:
    ).execute
  rescue => e
    Rails.logger.error(e)
    notify_failure(current_user, ticket, e.message)
  end

  private

  def notify_failure(current_user, ticket, error_message)
    OnlineNotification.add(
      user_id:       current_user.id,
      kind:          'kb_answer_generation_failed',
      seen:          false,
      data:          {
        error_message:,
        ticket_title:  ticket.title,
      },
      created_by_id: 1,
    )
  end
end
