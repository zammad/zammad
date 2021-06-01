# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ServiceNowConfig < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Defines postmaster filter.',
      name:        '5400_postmaster_filter_service_now_check',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to identify service now mails for correct follow-ups.',
      options:     {},
      state:       'Channel::Filter::ServiceNowCheck',
      frontend:    false
    )

    Setting.create_if_not_exists(
      title:       'Defines postmaster filter.',
      name:        '5401_postmaster_filter_service_now_check',
      area:        'Postmaster::PostFilter',
      description: 'Defines postmaster filter to identify service now mails for correct follow-ups.',
      options:     {},
      state:       'Channel::Filter::ServiceNowCheck',
      frontend:    false
    )
  end

end
