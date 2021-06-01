# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ChangeAuthorizationTokenSize < ActiveRecord::Migration[5.1]
  def up
    # return if it's a new setup to avoid running the migration
    return if !Setting.exists?(name: 'system_init_done')

    change_column :authorizations, :token, :string, limit: 2500

  end

end
