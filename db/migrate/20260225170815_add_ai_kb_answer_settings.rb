# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddAIKbAnswerSettings < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.create_if_not_exists(
      name:        'admin.ai_assistance_kb_answer_from_ticket_generation',
      label:       'AI Knowledge Base Answers',
      description: 'Manage AI generation of knowledge base answers from tickets.',
      preferences: { prio: 1337 }
    )

    Setting.create_if_not_exists(
      title:       'AI Knowledge Base Answer from Ticket',
      name:        'ai_assistance_kb_answer_from_ticket_generation',
      area:        'AI::Assistance',
      description: 'Enable or disable AI generation of knowledge base answers from ticket content.',
      options:     {},
      state:       false,
      preferences: {
        authentication: true,
        permission:     ['admin.ai_assistance_kb_answer_from_ticket_generation'],
      },
      frontend:    true,
    )
  end
end
