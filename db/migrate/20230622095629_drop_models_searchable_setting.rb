# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class DropModelsSearchableSetting < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'models_searchable').destroy
  end
end
