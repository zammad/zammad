# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class DoNotImportOnwNotifications731 < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Define postmaster filter.',
      name:        '0014_postmaster_filter_own_notification_loop_detection',
      area:        'Postmaster::PreFilter',
      description: 'Define postmaster filter to check if email is a own created notification email, then ignore it to prevent email loops.',
      options:     {},
      state:       'Channel::Filter::OwnNotificationLoopDetection',
      frontend:    false
    )

  end
end
