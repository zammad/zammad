
class UpdateToken < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    add_column :tokens, :preferences, :text, limit: 500.kilobytes + 1, null: true
  end
end
