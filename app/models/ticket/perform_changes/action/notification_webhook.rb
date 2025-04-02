# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Ticket::PerformChanges::Action::NotificationWebhook < Ticket::PerformChanges::Action

  def self.phase
    :after_save
  end

  def execute(...)
    TriggerWebhookJob.perform_later(performable,
                                    record,
                                    article,
                                    changes:        record.human_changes(context_data.try(:dig, :changes), record),
                                    user_id:        context_data.try(:dig, :user_id),
                                    execution_type: origin,
                                    event_type:     context_data.try(:dig, :type))
  end
end
