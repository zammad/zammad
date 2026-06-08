# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Ticket::PerformChanges::Action::NotificationWebhook < Ticket::PerformChanges::Action

  def self.phase
    :after_commit
  end

  def execute(...)
    changes = record.human_changes(context_data.try(:dig, :changes), record)

    webhook_ids.each do |webhook_id|
      TriggerWebhookJob.perform_later(performable,
                                      record,
                                      article,
                                      webhook_id:     webhook_id,
                                      changes:        changes,
                                      user_id:        context_data.try(:dig, :user_id),
                                      execution_type: origin,
                                      event_type:     context_data.try(:dig, :type))
    end
  end

  private

  # The value was a single id in the past (single-select) and is an array now, so we
  #   normalize to an array and spawn one parallel job per webhook. Ids are cast to
  #   integers before deduplication so that mixed types (e.g. [1, "1"] from API/seeds)
  #   don't enqueue duplicate jobs for the same webhook.
  def webhook_ids
    Array.wrap(execution_data['webhook_id']).compact_blank.map(&:to_i).uniq
  end
end
