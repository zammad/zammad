class ChatIncreaseMessageSize < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    change_column :chat_messages, :content, :text, limit: 20.megabytes + 1, null: false
  end

end
