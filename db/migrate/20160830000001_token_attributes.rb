class TokenAttributes < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    add_column :tokens, :last_used_at, :timestamp, limit: 3, null: true
    add_column :tokens, :expires_at, :date, null: true
  end
end
