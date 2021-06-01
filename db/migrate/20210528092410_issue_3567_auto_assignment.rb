# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue3567AutoAssignment < ActiveRecord::Migration[5.2]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.get('ticket_auto_assignment_selector')
    return if setting.blank?
    return if setting['condition'].blank?

    setting['condition'].each_key do |key|
      next if !key.start_with?('article.')

      setting['condition'].delete(key)
    end

    Setting.set('ticket_auto_assignment_selector', setting)
  end
end
