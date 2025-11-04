# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AIAssistanceTicketSummarizeImprovements < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    update_ticket_summary_config
    cleanup_stored_results
  end

  def update_ticket_summary_config
    Setting.find_by(name: 'ai_assistance_ticket_summary_config')&.tap do |setting|
      setting.state_current[:value].delete(:suggestions)
      setting.state_current[:value][:upcoming_events] = true
      setting.state_current[:value][:customer_sentiment] = true

      setting.state_initial = {
        value: {
          open_questions:     true,
          upcoming_events:    true,
          customer_sentiment: true,
          generate_on:        'on_ticket_detail_opening',
        },
      }

      setting.save!
    end
  end

  def cleanup_stored_results
    AI::StoredResult.where(identifier: 'ticket_summarize').destroy_all
  end
end
