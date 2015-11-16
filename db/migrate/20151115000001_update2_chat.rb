class Update2Chat < ActiveRecord::Migration
  def up
    add_column :chats, :public, :boolean, null: false, default: false
    drop_table :chat_topics
  end
end
