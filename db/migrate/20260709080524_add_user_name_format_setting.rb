# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddUserNameFormatSetting < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_or_update(
      title:       'User Name Format',
      name:        'user_name_format',
      area:        'System::Branding',
      description: 'Defines how user names are displayed in dropdowns, overviews and selection fields.',
      options:     {
        form: [
          {
            display:   '',
            null:      false,
            name:      'user_name_format',
            tag:       'select',
            options:   {
              first_last:       'Firstname Lastname',
              last_first:       'Lastname Firstname',
              last_first_comma: 'Lastname, Firstname',
            },
            translate: true,
          },
        ],
      },
      preferences: {
        render:     true,
        prio:       11,
        permission: ['admin.branding'],
      },
      state:       'first_last',
      frontend:    true
    )
  end
end
