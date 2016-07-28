class UpdateTextModule < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    add_column :text_modules, :foreign_id, :integer, null: true

  end
end
