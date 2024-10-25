# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class MoveChecklistTicketRelationToTicket < ActiveRecord::Migration[5.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_table :tickets do |t|
      t.references :checklist, null: true, foreign_key: true, index: { unique: true }
    end

    Ticket.reset_column_information

    Checklist.in_batches.each_record do |checklist|
      Ticket.find(checklist.ticket_id).update!(checklist:)
    end

    remove_reference :checklists, :ticket

    Checklist.reset_column_information
  end
end
