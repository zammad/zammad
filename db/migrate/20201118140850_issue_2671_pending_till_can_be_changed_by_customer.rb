# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue2671PendingTillCanBeChangedByCustomer < ActiveRecord::Migration[5.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    attr = ObjectManager::Attribute.find_by name: :pending_time
    attr.data_option[:permission] = %w[ticket.agent]
    attr.save!
  end
end
