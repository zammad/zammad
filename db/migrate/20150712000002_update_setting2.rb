class UpdateSetting2 < ActiveRecord::Migration
  def up

    # add preferences
    add_column :settings, :preferences, :string, limit: 2000, null: true
    Setting.reset_column_information

  end
end
