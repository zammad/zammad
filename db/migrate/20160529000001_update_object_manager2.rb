class UpdateObjectManager2 < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    add_column :object_manager_attributes, :to_config, :boolean, null: false, default: false
    add_column :object_manager_attributes, :data_option_new, :string, limit: 8000, null: true, default: false

  end
end
