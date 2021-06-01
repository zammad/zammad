# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class LoginEmailLength650 < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_column(:users, :login, :string, limit: 255)
    change_column(:users, :email, :string, limit: 255)
  end
end
