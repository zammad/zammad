
class UserPreferencesUpdate < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    User.update_default_preferences_by_permission('ticket.agent')
  end
end
