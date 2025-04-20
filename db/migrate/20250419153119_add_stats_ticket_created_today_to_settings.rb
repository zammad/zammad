# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AddStatsTicketCreatedTodayToSettings < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # add the dashboard stats backend for 'Stats::TicketCreatedToday'
    Setting.create_if_not_exists(
      title:       'Stats Backend',
      name:        'Stats::TicketCreatedToday',
      area:        'Dashboard::Stats',
      description: 'Defines a dashboard stats backend that gets scheduled automatically.',
      options:     {},
      state:       'Stats::TicketCreatedToday',
      preferences: {
        permission: ['ticket.agent'],
        prio:       7,
      },
      frontend:    false
    )
  end
end
