# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CtiUserProfile < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'cti customer last activity',
      name:        'cti_customer_last_activity',
      area:        'Integration::Cti',
      description: 'Defines the range in seconds of customer activity to trigger the user profile dialog on call.',
      options:     {},
      state:       30.days,
      preferences: {
        prio:       2,
        permission: ['admin.integration'],
      },
      frontend:    false,
    )
  end
end
