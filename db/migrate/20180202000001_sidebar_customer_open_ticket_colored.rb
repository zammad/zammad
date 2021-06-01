# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SidebarCustomerOpenTicketColored < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Open ticket indicator',
      name:        'ui_sidebar_open_ticket_indicator_colored',
      area:        'UI::Sidebar',
      description: 'Color representation of the open ticket indicator in the sidebar.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_sidebar_open_ticket_indicator_colored',
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
        permission: ['admin.ui'],
      },
      frontend:    true
    )
  end
end
