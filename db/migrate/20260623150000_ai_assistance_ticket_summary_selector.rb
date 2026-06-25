# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AIAssistanceTicketSummarySelector < ActiveRecord::Migration[8.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    remove_disabled_summary_generation_option
    reset_disabled_group_summary_generation

    Setting.create_if_not_exists(
      title:       'Ticket Summary Selector',
      name:        'ai_assistance_ticket_summary_selector',
      area:        'AI::Assistance',
      description: 'Enable ticket summary for following matching tickets.',
      options:     {
        form: [
          {},
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.ai_assistance_ticket_summary'],
      },
      state:       {},
      frontend:    true,
    )
  end

  private

  def remove_disabled_summary_generation_option
    attribute = ObjectManager::Attribute.get(
      object: 'Group',
      name:   'summary_generation',
    )
    return if !attribute

    options = attribute.data_option['options'] || []
    options = options.reject { |option| option['value'] == 'disabled' }
    return if options == attribute.data_option['options']

    attribute.data_option['options'] = options
    attribute.save!
  end

  def reset_disabled_group_summary_generation
    return if Group.column_names.exclude?('summary_generation')

    Group.where(summary_generation: 'disabled').update_all(summary_generation: 'global_default') # rubocop:disable Rails/SkipsModelValidations
  end
end
