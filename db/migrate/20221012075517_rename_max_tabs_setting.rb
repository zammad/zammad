# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class RenameMaxTabsSetting < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'ui_task_mananger_max_task_count')
    setting.title = 'Maximum number of open tabs.'
    setting.description = 'Defines the maximum number of allowed open tabs before auto cleanup removes surplus tabs when creating new tabs.'
    setting.save!
  end
end
