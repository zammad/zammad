# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TaskbarUpdatePreferenceTasks < ActiveRecord::Migration[6.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Taskbar.in_batches.each_record do |elem|
      elem.preferences ||= {}
      elem.preferences[:tasks] = elem.send(:collect_related_tasks)
      elem.save!
    end
  end
end
