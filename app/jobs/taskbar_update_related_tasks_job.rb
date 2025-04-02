# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TaskbarUpdateRelatedTasksJob < ApplicationJob
  def perform(task_ids)
    Taskbar.where(id: task_ids).each do |taskbar|
      taskbar.with_lock do
        taskbar.update!(
          preferences:       taskbar.preferences.merge(tasks: taskbar.collect_related_tasks),
          local_update:      true,
          skip_item_trigger: true,
        )
      end
    end
  end
end
