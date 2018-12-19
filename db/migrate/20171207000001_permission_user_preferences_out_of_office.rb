class PermissionUserPreferencesOutOfOffice < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

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
