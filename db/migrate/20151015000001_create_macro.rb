class CreateMacro < ActiveRecord::Migration
  def up
    create_table :macros do |t|
      t.string  :name,                   limit: 250,  null: true
      t.string  :perform,                limit: 5000, null: false
      t.boolean :active,                              null: false, default: true
      t.string  :note,                   limit: 250,  null: true
      t.integer :updated_by_id,                       null: false
      t.integer :created_by_id,                       null: false
      t.timestamps                                    null: false
    end
    add_index :macros, [:name], unique: true

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    UserInfo.current_user_id = 1
    Macro.create_or_update(
      name: 'Close & Tag as Spam',
      perform: {
        'ticket.state_id' => {
          value: Ticket::State.find_by(name: 'closed').id,
        },
        'ticket.tags' => {
          operator: 'add',
          value: 'spam',
        },
      },
      note: 'example macro',
      active: true,
    )
  end

  def down
    drop_table :macros
  end
end
