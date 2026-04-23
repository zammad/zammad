# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class TriggerAIAgentJob < AIJob
  include HasActiveJobLock

  attr_reader :ticket, :ai_agent, :article, :changes, :user_id, :execution_type, :event_type

  discard_on(Exception) do |job, e|
    Rails.logger.info 'An unexpected error occurred while executing TriggerAIAgentJob. Discarding job. See exception for further details.'
    Rails.logger.info e

    job.mark_as_gone!
  end

  retry_on Service::AI::Agent::Run::TemporaryError, attempts: 5, wait: lambda { |executions|
    executions * 10.seconds
  } do |job, e|
    Rails.logger.info 'AI Service encountered a temporary error, but it persisted for too long. Discarding job. See exception for further details.'
    Rails.logger.info e
    job.mark_as_gone!
  end

  discard_on(Service::AI::Agent::Run::PermanentError) do |job, e|
    Rails.logger.info 'AI Service encountered a permanent error. Discarding job. See exception for further details.'
    Rails.logger.info e

    job.mark_as_gone!
  end

  # Please note that ticket.ai_agent_running flag may get stuck after this error.
  # Next successful job execution will clean it up.
  discard_on(ActiveJob::DeserializationError) do |_job, e|
    Rails.logger.info 'AI Agent, Ticket or Article may got removed before TriggerAIAgentJob could be executed. Discarding job. See exception for further details.'
    Rails.logger.info e
  end

  def lock_key
    @ai_agent = arguments[0]
    @ticket   = arguments[1]

    # "TriggerAIAgentJob/123/Ticket/42/AIAgent/123"
    "#{self.class.name}/Ticket/#{ticket.id}/AIAgent/#{ai_agent.id}"
  end

  def perform(ai_agent, ticket, article, changes:, user_id:, execution_type:, event_type:)
    @ai_agent = ai_agent
    @ticket   = ticket
    @article  = article

    # Following arguments currently are not used.
    # They're added for compatibility reasons to match the interface of TriggerWebhookJob.
    @changes    = changes
    @user_id    = user_id
    @execution_type = execution_type
    @event_type = event_type

    Service::AI::Agent::Run
      .execute(ai_agent:, ticket:, article:)

    mark_as_gone!
  end

  def mark_as_gone!
    ticket = arguments[1]

    return if ticket.nil?

    ApplicationModel.current_transaction.after_commit do
      AIAgentMarkAsGone.perform_later(ticket)
    end
  end
end
