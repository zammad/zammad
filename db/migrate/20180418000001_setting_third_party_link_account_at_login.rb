# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingThirdPartyLinkAccountAtLogin < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Automatic account link on initial logon',
      name:        'auth_third_party_auto_link_at_inital_login',
      area:        'Security::ThirdPartyAuthentication',
      description: 'Enables the automatic linking of an existing account on initial login via a third party application. If this is disabled, an existing user must first log into Zammad and then link his "Third Party" account to his Zammad account via Profile -> Linked Accounts.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'auth_third_party_auto_link_at_inital_login',
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
        prio:       10,
      },
      state:       false,
      frontend:    false
    )
  end
end
