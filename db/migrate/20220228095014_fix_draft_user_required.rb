# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class FixDraftUserRequired < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_column :ticket_shared_draft_zooms, :created_by_id, :integer, null: false
    change_column :ticket_shared_draft_zooms, :updated_by_id, :integer, null: false
    change_column :ticket_shared_draft_starts, :created_by_id, :integer, null: false
    change_column :ticket_shared_draft_starts, :updated_by_id, :integer, null: false

    Ticket::SharedDraftStart.reset_column_information
    Ticket::SharedDraftZoom.reset_column_information
  end
end
