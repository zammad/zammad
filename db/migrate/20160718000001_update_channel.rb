
class UpdateChannel < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    change_column :channels, :options, :text, limit: 500.kilobytes + 1,  null: true
  end
end
