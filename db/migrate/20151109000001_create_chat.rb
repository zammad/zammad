class CreateChat < ActiveRecord::Migration
  def up
    create_table :chats do |t|
      t.string  :name,                   limit: 250,  null: true
      t.integer :max_queue,                           null: false, default: 5
      t.string  :note,                   limit: 250,  null: true
      t.boolean :active,                              null: false, default: true
      t.boolean :public,                              null: false, default: false
      t.string  :preferences,            limit: 5000, null: true
      t.integer :updated_by_id,                       null: false
      t.integer :created_by_id,                       null: false
      t.timestamps                                    null: false
    end
    add_index :chats, [:name], unique: true

    create_table :chat_topics do |t|
      t.integer :chat_id,                             null: false
      t.string  :name,                   limit: 250,  null: false
      t.string  :note,                   limit: 250,  null: true
      t.integer :updated_by_id,                       null: false
      t.integer :created_by_id,                       null: false
      t.timestamps                                    null: false
    end
    add_index :chat_topics, [:name], unique: true

    create_table :chat_sessions do |t|
      t.integer :chat_id,                             null: false
      t.string  :session_id,                          null: false
      t.string  :name,                   limit: 250,  null: true
      t.string  :state,                  limit:  50,  null: false, default: 'waiting' # running, closed
      t.integer :user_id,                             null: true
      t.text    :preferences,            limit: 100.kilobytes + 1, null: true
      t.integer :updated_by_id,                       null: true
      t.integer :created_by_id,                       null: true
      t.timestamps                                    null: false
    end
    add_index :chat_sessions, [:session_id]
    add_index :chat_sessions, [:state]
    add_index :chat_sessions, [:user_id]
    add_index :chat_sessions, [:chat_id]

    create_table :chat_messages do |t|
      t.integer :chat_session_id,                     null: false
      t.string  :content,                limit: 5000, null: false
      t.integer :created_by_id,                       null: true
      t.timestamps                                    null: false
    end
    add_index :chat_messages, [:chat_session_id]

    create_table :chat_agents do |t|
      t.boolean :active,                              null: false, default: true
      t.integer :concurrent,                          null: false, default: 5
      t.integer :updated_by_id,                       null: false
      t.integer :created_by_id,                       null: false
      t.timestamps                                    null: false
    end
    add_index :chat_agents, [:active]
    add_index :chat_agents, [:updated_by_id], unique: true
    add_index :chat_agents, [:created_by_id], unique: true

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Role.create_if_not_exists(
      name: 'Chat',
      note: 'Access to chat feature.',
      updated_by_id: 1,
      created_by_id: 1
    )

    chat = Chat.create(
      name: 'default',
      max_queue: 5,
      note: '',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

  end

  def down
    drop_table :chat_topics
    drop_table :chat_sessions
    drop_table :chat_messages
    drop_table :chat_agents
    drop_table :chats
  end
end
