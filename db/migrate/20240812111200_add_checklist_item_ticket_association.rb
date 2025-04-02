# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AddChecklistItemTicketAssociation < ActiveRecord::Migration[5.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_reference :checklist_items, :ticket, foreign_key: true

    Checklist::Item.reset_column_information
  end
end
