# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Ticket::PerformChanges::Action::AIAgent < Ticket::PerformChanges::Action

  def self.phase
    :before_save
  end

  def execute(...)
    ai_agent = AI::Agent.from_performable(performable)

    if ai_agent.blank?
      Rails.logger.info 'No AI Agent found for performable, skipping TriggerAIAgentJob.'
      return
    end

    record.ai_agent_running = true

    ApplicationModel.current_transaction.after_commit do
      TriggerAIAgentJob.perform_later(ai_agent,
                                      record,
                                      article,
                                      changes:        record.human_changes(context_data.try(:dig, :changes), record),
                                      user_id:        context_data.try(:dig, :user_id),
                                      execution_type: origin,
                                      event_type:     context_data.try(:dig, :type))
    end
  end
end
