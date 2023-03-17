# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class ChatIncreaseMessageSize < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_column :chat_messages, :content, :text, limit: 20.megabytes + 1, null: false
  end

end
