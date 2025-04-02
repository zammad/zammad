# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class DuplicateSettingTitles < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    settings_update = {
      'ticket_auto_assignment_selector'        => 'Auto Assignment Selector',
      'ticket_auto_assignment_user_ids_ignore' => 'Auto Assignment Ignored Users',
    }

    settings_update.each do |name, title|
      Setting.find_by(name: name)&.update!(title: title)
    end
  end
end
