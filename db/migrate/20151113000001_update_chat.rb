class UpdateChat < ActiveRecord::Migration
  def up
    add_index :chat_sessions, [:session_id]
    add_index :chat_sessions, [:chat_id]
    add_index :chat_messages, [:chat_session_id]
    add_index :chat_agents, [:active]
    add_index :chat_agents, [:updated_by_id], unique: true
  end
end
