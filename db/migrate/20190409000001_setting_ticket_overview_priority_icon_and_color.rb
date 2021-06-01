# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingTicketOverviewPriorityIconAndColor < ActiveRecord::Migration[5.1]
  def change
    Setting.create_if_not_exists(
      title:       'Priority Icons in Overviews',
      name:        'ui_ticket_overview_priority_icon',
      area:        'UI::TicketOverview::PriorityIcons',
      description: 'Enables priority icons in ticket overviews.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_ticket_overview_priority_icon',
            tag:       'boolean',
            translate: true,
            options:   {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        prio:       500,
        permission: ['admin.ui'],
      },
      frontend:    true
    )

    if ActiveRecord::Base.connection.columns('ticket_priorities').map(&:name).exclude?('ui_icon')
      add_column :ticket_priorities, :ui_icon, :string, limit: 100, null: true
    end
    if ActiveRecord::Base.connection.columns('ticket_priorities').map(&:name).exclude?('ui_color')
      add_column :ticket_priorities, :ui_color, :string, limit: 100, null: true
    end
    Ticket::Priority.reset_column_information

    priority = Ticket::Priority.find_by(name: '1 low')
    priority&.update!(ui_icon: 'low-priority', ui_color: 'low-priority')
    priority = Ticket::Priority.find_by(name: '3 high')
    priority&.update!(ui_icon: 'important', ui_color: 'high-priority')
  end
end
