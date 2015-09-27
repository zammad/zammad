class UpdateSettings6 < ActiveRecord::Migration
  def up
    return if !Setting.column_names.include?('state')
    rename_column :settings, :state, :state_current
  end
end
