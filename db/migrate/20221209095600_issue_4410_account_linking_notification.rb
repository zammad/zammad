# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4410AccountLinkingNotification < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Automatic account linking notification',
      name:        'auth_third_party_linking_notification',
      area:        'Security::ThirdPartyAuthentication',
      description: 'Enables sending of an email notification to a user when they link their account with a third-party application.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'auth_third_party_linking_notification',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        permission: ['admin.security'],
        prio:       20,
      },
      state:       false,
      frontend:    false
    )
  end
end
