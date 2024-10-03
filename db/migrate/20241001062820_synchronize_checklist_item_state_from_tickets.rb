# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SynchronizeChecklistItemStateFromTickets < ActiveRecord::Migration[7.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    update_checklist_items
  end

  def update_checklist_items
    Checklist::Item.where.not(ticket_id: nil).each do |item|
      item.update!(checked: Checklist.ticket_closed?(item.ticket))
    end
  end
end
