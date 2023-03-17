# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3503FixCurrentUser < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    remove_current_user(Job)
    remove_current_user(Sla)
  end

  def remove_current_user(target)
    target.find_each do |row|
      row.condition.each do |key, condition|
        next if condition['pre_condition'].blank?
        next if condition['pre_condition'].exclude?('current_user')

        row.condition.delete(key)
        row.save
      end
    end
  end
end
