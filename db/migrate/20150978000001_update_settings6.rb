class UpdateSettings6 < ActiveRecord::Migration
  def up
    if Setting.column_names.include?('state')
      rename_column :settings, :state, :state_current
    end
  end
end
