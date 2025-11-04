# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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

  discard_on(ActiveJob::DeserializationError) do |job, e|
    Rails.logger.info 'AI Agent, Ticket or Article may got removed before TriggerAIAgentJob could be executed. Discarding job. See exception for further details.'
    Rails.logger.info e

    job.mark_as_gone!
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
      .new(ai_agent:, ticket:, article:)
      .execute

    mark_as_gone!
  end

  def self.working_on(ticket, exclude: nil)
    ActiveJobLock
      .where('lock_key LIKE ?', "#{name}/Ticket/#{ticket.id}/AIAgent/%")
      .then do |scope|
        next scope if !exclude

        scope.where.not(active_job_id: exclude.job_id)
      end
  end

  def self.working_on?(ticket, exclude: nil)
    working_on(ticket, exclude:).exists?
  end

  def mark_as_gone!
    # arguments are empty if it was not possible to deserialize them
    return if arguments.empty?

    @ai_agent = arguments[0]
    @ticket   = arguments[1]

    self.class.update_ticket(ticket, exclude: self)
  end

  def self.update_ticket(ticket, exclude: nil)
    ticket.with_lock do
      ticket.ai_agent_running = working_on?(ticket, exclude:)
      ticket.save!
    end
  end
end
