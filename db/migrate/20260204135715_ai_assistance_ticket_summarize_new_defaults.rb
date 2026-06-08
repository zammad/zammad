# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AIAssistanceTicketSummarizeNewDefaults < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    update_defaults
  end

  private

  def update_defaults
    Setting.find_by(name: 'ai_assistance_ticket_summary_config')&.tap do |setting|
      setting.state_initial = {
        value: {
          open_questions:     false,
          upcoming_events:    false,
          customer_sentiment: true,
          generate_on:        'on_ticket_detail_opening',
        },
      }

      setting.save!
    end
  end
end
