# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Issue5381FixDescription < ActiveRecord::Migration[7.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'auth_third_party_no_create_user').update!(description: 'Disables user creation on logon with a third-party application.')
  end
end
