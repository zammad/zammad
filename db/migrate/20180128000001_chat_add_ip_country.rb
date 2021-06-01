# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ChatAddIpCountry < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column :chats, :block_ip, :string, limit: 5000, null: true
    add_column :chats, :block_country, :string, limit: 5000, null: true
  end
end
