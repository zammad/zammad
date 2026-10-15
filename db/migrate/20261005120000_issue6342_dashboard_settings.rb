# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6342DashboardSettings < ActiveRecord::Migration[8.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_permission
    add_dashboard_setting
    add_dashboard_activity_stream_setting
    add_dashboard_activity_stream_own_setting
    add_dashboard_first_steps_setting
    add_dashboard_stats_settings
  end

  private

  def add_permission
    Permission.create_if_not_exists(
      name:        'admin.dashboard',
      label:       'Dashboard',
      description: 'Manage dashboard settings of your system.',
      preferences: { prio: 1305 }
    )
  end

  def add_dashboard_setting
    Setting.create_if_not_exists(
      title:       'Dashboard',
      name:        'dashboard',
      area:        'Dashboard::Base',
      description: 'Enable the dashboard.',
      options:     {},
      preferences: {
        authentication: true,
        permission:     ['admin.dashboard'],
      },
      state:       true,
      frontend:    true
    )
  end

  def add_dashboard_activity_stream_setting
    Setting.create_if_not_exists(
      title:       'Dashboard activity stream',
      name:        'dashboard_activity_stream',
      area:        'Dashboard::Base',
      description: 'Enable the activity stream on the dashboard.',
      options:     {},
      preferences: {
        authentication: true,
        permission:     ['admin.dashboard'],
      },
      state:       true,
      frontend:    true
    )
  end

  def add_dashboard_activity_stream_own_setting
    Setting.create_if_not_exists(
      title:       'Dashboard activity stream own activities',
      name:        'dashboard_activity_stream_own',
      area:        'Dashboard::Base',
      description: 'Show agents only their own activities in the activity stream.',
      options:     {},
      preferences: {
        authentication: true,
        permission:     ['admin.dashboard'],
      },
      state:       false,
      frontend:    true
    )
  end

  def add_dashboard_first_steps_setting
    Setting.create_if_not_exists(
      title:       'Dashboard first steps',
      name:        'dashboard_first_steps',
      area:        'Dashboard::Base',
      description: 'Enable the first steps tab on the dashboard.',
      options:     {},
      preferences: {
        authentication: true,
        permission:     ['admin.dashboard'],
      },
      state:       true,
      frontend:    true
    )
  end

  def add_dashboard_stats_settings
    {
      'ticket_waiting_time'         => 'waiting time',
      'ticket_escalation'           => 'mood',
      'ticket_channel_distribution' => 'channel distribution',
      'ticket_load_measure'         => 'assigned tickets',
      'ticket_in_process'           => 'tickets in process',
      'ticket_reopen'               => 'reopening rate',
    }.each do |widget, label|
      Setting.create_if_not_exists(
        title:       "Dashboard #{label} widget",
        name:        "dashboard_stats_#{widget}",
        area:        'Dashboard::Base',
        description: "Enable the #{label} widget on the dashboard.",
        options:     {},
        preferences: {
          authentication: true,
          permission:     ['admin.dashboard'],
        },
        state:       true,
        frontend:    true
      )
    end
  end
end
