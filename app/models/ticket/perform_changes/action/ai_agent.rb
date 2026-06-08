# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Ticket::PerformChanges::Action::AIAgent < Ticket::PerformChanges::Action

  def self.phase
    :before_save
  end

  def execute(...)
    ai_agents = AI::Agent.all_from_performable(performable).to_a

    if ai_agents.blank?
      Rails.logger.info 'No AI Agent found for performable, skipping TriggerAIAgentJob.'
      return
    end

    record.ai_agent_running = true

    changes = record.human_changes(context_data.try(:dig, :changes), record)

    ApplicationModel.current_transaction.after_commit do
      ai_agents.each do |ai_agent|
        TriggerAIAgentJob.perform_later(ai_agent,
                                        record,
                                        article,
                                        changes:        changes,
                                        user_id:        context_data.try(:dig, :user_id),
                                        execution_type: origin,
                                        event_type:     context_data.try(:dig, :type))
      end
    end
  end
end
