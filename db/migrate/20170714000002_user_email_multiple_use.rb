# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class UserEmailMultipleUse < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'User email for muliple users',
      name:        'user_email_multiple_use',
      area:        'Model::User',
      description: 'Allow to use email address for muliple users.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'user_email_multiple_use',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        permission: ['admin'],
      },
      frontend:    false
    )
  end

end
