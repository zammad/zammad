# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class InitSessionTimeout < ActiveRecord::Migration[5.2]
  def change

    return if !Setting.exists?(name: 'system_init_done')

    change_setting_prio('user_create_account', 10)
    change_setting_prio('user_lost_password', 20)

    two_days = 2.days.seconds

    Setting.create_if_not_exists(
      title:       'Session Timeout',
      name:        'session_timeout',
      area:        'Security::Base',
      description: 'Defines the session timeout for inactivity of users (in seconds).',
      options:     {
        form: [
          {
            display: 'Default',
            null:    false,
            name:    'default',
            tag:     'input',
          },
          {
            display: 'admin',
            null:    false,
            name:    'admin',
            tag:     'input',
          },
          {
            display: 'ticket.agent',
            null:    false,
            name:    'ticket.agent',
            tag:     'input',
          },
          {
            display: 'ticket.customer',
            null:    false,
            name:    'ticket.customer',
            tag:     'input',
          },
        ],
      },
      preferences: {
        prio: 30,
      },
      state:       {
        'default'         => two_days,
        'admin'           => two_days,
        'ticket.agent'    => two_days,
        'ticket.customer' => two_days,
      },
      frontend:    true
    )

    Scheduler.create_or_update(
      name:          'Cleanup dead sessions.',
      method:        'SessionTimeoutJob.perform_now',
      period:        1.minute,
      last_run:      1.day.from_now,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  def change_setting_prio(name, prio)
    setting = Setting.find_by(name: name)
    setting.preferences[:prio] = prio
    setting.save
  end
end
