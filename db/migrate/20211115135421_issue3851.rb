# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3851 < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    fix_follow_up_assignment
    fix_follow_up_possible
  end

  def fix_follow_up_assignment
    follow_up_assignment = ObjectManager::Attribute.for_object('Group').find_by(name: 'follow_up_assignment')
    follow_up_assignment.data_option['default'] = 'true'
    follow_up_assignment.screens['create']['-all-']['null'] = false
    follow_up_assignment.screens['edit']['-all-']['null'] = false
    follow_up_assignment.save!
  end

  def fix_follow_up_possible
    follow_up_possible = ObjectManager::Attribute.for_object('Group').find_by(name: 'follow_up_possible')
    follow_up_possible.screens['create']['-all-']['null'] = false
    follow_up_possible.screens['edit']['-all-']['null'] = false
    follow_up_possible.save!
  end
end
