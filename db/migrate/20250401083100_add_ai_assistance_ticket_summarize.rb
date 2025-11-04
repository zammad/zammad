# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AddAIAssistanceTicketSummarize < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.create_if_not_exists(
      name:        'admin.ai',
      label:       'AI',
      description: 'Manage AI settings of your system.',
      preferences: { prio: 1333 }
    )
    Permission.create_if_not_exists(
      name:        'admin.ai_assistance_ticket_summary',
      label:       'Ticket Summary',
      description: 'Manage ticket summarization of your system.',
      preferences: { prio: 1334 }
    )

    Setting.create_if_not_exists(
      title:       'AI provider',
      name:        'ai_provider',
      area:        'AI::Provider',
      description: 'Stores the AI provider.',
      options:     {},
      state:       '',
      preferences: {
        authentication: true,
        permission:     ['admin.ai'],
        validations:    [
          # This validaiton is now gone
          # 'Setting::Validation::AIProvider',
        ],
      },
      frontend:    true,
    )

    Setting.create_if_not_exists(
      title:       'AI Provider Config',
      name:        'ai_provider_config',
      area:        'AI::Provider',
      description: 'Stores the AI provider configuration.',
      options:     {},
      state:       {},
      preferences: {
        permission:  ['admin.ai'],
        validations: [
          'Setting::Validation::AIProviderConfig',
        ],
      },
      frontend:    false,
    )

    Setting.create_if_not_exists(
      title:       'Ticket Summary',
      name:        'ai_assistance_ticket_summary',
      area:        'AI::Assistance',
      description: 'Enable or disable the AI assistance ticket summary.',
      options:     {},
      state:       false,
      preferences: {
        authentication: true,
        permission:     ['admin.ai_assistance_ticket_summary'],
      },
      frontend:    true,
    )

    Setting.create_if_not_exists(
      title:       'Ticket Summary Config',
      name:        'ai_assistance_ticket_summary_config',
      area:        'AI::Assistance',
      description: 'Stores the AI assistance ticket summarization options (e.g. which content is visible).',
      options:     {},
      state:       {
        open_questions: true,
        suggestions:    false,
      },
      preferences: {
        authentication: true,
        permission:     ['admin.ai_assistance_ticket_summary'],
      },
      frontend:    true,
    )
  end
end
