# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class DropKarma < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    drop_table :karma_activity_logs
    drop_table :karma_activities
    drop_table :karma_users

    Setting.find_by(name: 'karma_levels')&.destroy
    Setting.find_by(name: '9200_karma')&.destroy
  end
end
