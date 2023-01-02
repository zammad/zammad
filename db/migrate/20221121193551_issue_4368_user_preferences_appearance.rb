# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4368UserPreferencesAppearance < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.create_if_not_exists(
      name:         'user_preferences.appearance',
      note:         'Manage %s',
      preferences:  {
        translations: ['Appearance']
      },
      allow_signup: true,
    )

    customer = Role.find_by(name: 'Customer')
    customer&.permission_grant('user_preferences.appearance')
  end
end
