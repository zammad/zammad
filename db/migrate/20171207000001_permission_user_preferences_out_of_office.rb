# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class PermissionUserPreferencesOutOfOffice < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.create_if_not_exists(
      name:        'user_preferences.out_of_office',
      note:        'Change %s',
      preferences: {
        translations: ['Out of Office'],
        required:     ['ticket.agent'],
      },
    )
  end

end
