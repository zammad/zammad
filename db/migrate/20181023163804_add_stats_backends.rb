# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class AddStatsBackends < ActiveRecord::Migration[5.1]

  def up

    return if !Setting.exists?(name: 'system_init_done')

    # add the dashboard stats backend for 'Stats::TicketWaitingTime'
    Setting.create_if_not_exists(
      title:       'Stats Backend',
      name:        'Stats::TicketWaitingTime',
      area:        'Dashboard::Stats',
      description: 'Defines a dashboard stats backend that get scheduled automatically.',
      options:     {},
      state:       'Stats::TicketWaitingTime',
      preferences: {
        permission: ['ticket.agent'],
        prio:       1,
      },
      frontend:    false
    )

    # add the dashboard stats backend for 'Stats::TicketEscalation'
    Setting.create_if_not_exists(
      title:       'Stats Backend',
      name:        'Stats::TicketEscalation',
      area:        'Dashboard::Stats',
      description: 'Defines a dashboard stats backend that get scheduled automatically.',
      options:     {},
      state:       'Stats::TicketEscalation',
      preferences: {
        permission: ['ticket.agent'],
        prio:       2,
      },
      frontend:    false
    )

    # add the dashboard stats backend for 'Stats::TicketChannelDistribution'
    Setting.create_if_not_exists(
      title:       'Stats Backend',
      name:        'Stats::TicketChannelDistribution',
      area:        'Dashboard::Stats',
      description: 'Defines a dashboard stats backend that get scheduled automatically.',
      options:     {},
      state:       'Stats::TicketChannelDistribution',
      preferences: {
        permission: ['ticket.agent'],
        prio:       3,
      },
      frontend:    false
    )

    # add the dashboard stats backend for 'Stats::TicketLoadMeasure'
    Setting.create_if_not_exists(
      title:       'Stats Backend',
      name:        'Stats::TicketLoadMeasure',
      area:        'Dashboard::Stats',
      description: 'Defines a dashboard stats backend that get scheduled automatically.',
      options:     {},
      state:       'Stats::TicketLoadMeasure',
      preferences: {
        permission: ['ticket.agent'],
        prio:       4,
      },
      frontend:    false
    )

    # add the dashboard stats backend for 'Stats::TicketInProcess'
    Setting.create_if_not_exists(
      title:       'Stats Backend',
      name:        'Stats::TicketInProcess',
      area:        'Dashboard::Stats',
      description: 'Defines a dashboard stats backend that get scheduled automatically.',
      options:     {},
      state:       'Stats::TicketInProcess',
      preferences: {
        permission: ['ticket.agent'],
        prio:       5,
      },
      frontend:    false
    )

    # add the dashboard stats backend for 'Stats::TicketReopen'
    Setting.create_if_not_exists(
      title:       'Stats Backend',
      name:        'Stats::TicketReopen',
      area:        'Dashboard::Stats',
      description: 'Defines a dashboard stats backend that get scheduled automatically.',
      options:     {},
      state:       'Stats::TicketReopen',
      preferences: {
        permission: ['ticket.agent'],
        prio:       6,
      },
      frontend:    false
    )

  end
end
