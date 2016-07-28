class UpdateSettingApi < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Setting.create_or_update(
      title: 'API Token Access',
      name: 'api_token_access',
      area: 'API::Base',
      description: 'Enable REST API using tokens (not username/email addeess and password). Each user need to create own access tokens in user profile.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'api_token_access',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: true,
      frontend: false
    )
    Setting.create_or_update(
      title: 'API Password Access',
      name: 'api_password_access',
      area: 'API::Base',
      description: 'Enable REST API access using the username/email address and password for the authentication user.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'api_password_access',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: true,
      frontend: false
    )
    add_column :tokens, :label, :string, limit: 255, null: true

  end
end
