# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class InclusiveWording < ActiveRecord::Migration[6.0]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    rename_column :chats, :whitelisted_websites, :allowed_websites
    Chat.reset_column_information
  end
end
