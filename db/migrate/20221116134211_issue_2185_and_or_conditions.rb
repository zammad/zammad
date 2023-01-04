# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue2185AndOrConditions < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # Add prio preference to existing ticket settings.
    #   Otherwise, the ordering on the same screen will be off.
    %w[ticket_hook ticket_hook_position ticket_last_contact_behaviour].each_with_index do |name, index|
      setting = Setting.find_by(name: name)
      setting[:preferences][:prio] = (index + 1) * 1000
      setting.save
    end

    # Create the new setting with correct prio.
    Setting.create_if_not_exists(
      title:       'Ticket Conditions Expert Mode',
      name:        'ticket_allow_expert_conditions',
      area:        'Ticket::Base',
      description: 'Defines if the ticket conditions editor supports complex logical expressions.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'ticket_allow_expert_conditions',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        prio:       4000,
        permission: ['admin.ticket'],
      },
      frontend:    true
    )
  end
end
