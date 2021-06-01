# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingPostmasterSendRejectEmail < ActiveRecord::Migration[5.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Send postmaster mail if mail too large',
      name:        'postmaster_send_reject_if_mail_too_large',
      area:        'Email::Base',
      description: 'Send postmaster reject mail to sender of mail if mail is too large.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'postmaster_send_reject_if_mail_too_large',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       true,
      preferences: {
        online_service_disable: true,
        permission:             ['admin.channel_email'],
      },
      frontend:    false
    )
  end
end
