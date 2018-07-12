class AddGroupDirectionToOverviews < ActiveRecord::Migration[5.1]
  def change
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    add_column :overviews, :group_direction, :string, limit: 250, null: true
  end
end
