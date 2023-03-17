# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4009FixTitle < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(title: 'Note - visibility confirmation dialog').update(title: 'Article - visibility confirmation dialog')
  end
end
