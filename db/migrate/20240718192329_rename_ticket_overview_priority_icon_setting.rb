# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class RenameTicketOverviewPriorityIconSetting < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by name: 'ui_ticket_overview_priority_icon'
    return if setting.blank?

    setting.update!(
      title:       'Ticket Priority Icons',
      name:        'ui_ticket_priority_icons',
      area:        'UI::Ticket::Priority',
      description: 'Enables display of ticket priority icons in UI.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_ticket_priority_icons',
            tag:       'boolean',
            translate: true,
            options:   {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
    )
  rescue => e
    Rails.logger.error e
  end
end
