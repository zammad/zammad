class UpdateDefaultPreferences < ActiveRecord::Migration
  def up
    User.update_default_preferences('Agent')
  end
end
