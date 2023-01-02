# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TicketOverviewTicketLimitSetting < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Maximum number of ticket shown in overviews',
      name:        'ui_ticket_overview_ticket_limit',
      area:        'UI::TicketOverview::TicketLimit',
      description: 'Define the maximum number of ticket shown in overviews.',
      options:     {},
      state:       2000,
      preferences: {
        permission: ['admin.overview'],
      },
      frontend:    true
    )
  end
end
