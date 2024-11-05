# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Issue5390TaskbarRemoveDuplicatedKeyByUser < ActiveRecord::Migration[7.1]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    duplicates = Taskbar.select(:user_id, :app, :key).group(:user_id, :app, :key).having('COUNT(*) > 1').reorder(nil)
    return if duplicates.blank?

    Taskbar
      .where(
        user_id: duplicates.pluck(:user_id),
        app:     duplicates.pluck(:app),
        key:     duplicates.pluck(:key)
      )
      .group_by { |taskbar| [taskbar.user_id, taskbar.app, taskbar.key] }
      .each_value do |records|
        newest_record = records.max_by(&:last_contact)

        records.reject { |record| record == newest_record }.each(&:destroy)
      end
  end
end
