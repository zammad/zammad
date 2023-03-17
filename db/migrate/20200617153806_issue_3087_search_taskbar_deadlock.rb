# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3087SearchTaskbarDeadlock < ActiveRecord::Migration[5.2]
  def change
    Taskbar.where(key: 'Search').find_each do |taskbar|
      next if taskbar.preferences.blank?
      next if taskbar.preferences[:tasks].blank?

      taskbar.preferences.delete(:tasks)

      taskbar.save!
    rescue => e
      Rails.logger.error e
    end
  end
end
