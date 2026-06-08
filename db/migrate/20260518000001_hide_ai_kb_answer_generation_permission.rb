# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class HideAIKbAnswerGenerationPermission < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.find_by(name: 'admin.ai_assistance_kb_answer_from_ticket_generation')&.update!(active: false)
  end
end
