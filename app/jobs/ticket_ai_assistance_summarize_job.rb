# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketAIAssistanceSummarizeJob < AIJob
  include HasActiveJobLock

  def lock_key
    "#{self.class.name}/#{arguments[0].id}/#{arguments[0].articles.last&.created_at}/#{arguments[1]}"
  end

  def perform(ticket, locale, regeneration_of: nil)
    summarize = Service::Ticket::AIAssistance::Summarize.new(
      locale:,
      ticket:,
      regeneration_of:,
    )

    ai_result = summarize.execute

    # Trigger the update for the new desktop view.
    trigger_subscription(ticket:, locale:, data: {
      summary:             ai_result&.content || {},
      ai_analytics_run_id: ai_result&.ai_analytics_run&.id,
    }.compact)

    # Trigger the update for the old stack
    broadcast({ ticket_id: ticket.id, locale: })
  rescue => e
    Rails.logger.error "TicketAIAssistanceSummarizeJob failed for ticket #{ticket.id}: #{e.message}\n#{e.backtrace.join("\n")}"

    trigger_subscription(ticket:, locale:, data: {
                           error: {
                             message:   e.message,
                             exception: e.class.name
                           }
                         })

    # Trigger the update for the old stack without real date (it will be refetched on frontend decision).
    broadcast({ ticket_id: ticket.id, locale:, error: true })
  end

  private

  def broadcast(data)
    Sessions.broadcast({
                         event: 'ticket::summary::update',
                         data:
                       })
  end

  def trigger_subscription(ticket:, locale:, data:)
    Gql::Subscriptions::Ticket::AIAssistance::SummaryUpdates.trigger(
      data,
      arguments: { ticket_id: Gql::ZammadSchema.id_from_object(ticket), locale: }
    )
  end
end
