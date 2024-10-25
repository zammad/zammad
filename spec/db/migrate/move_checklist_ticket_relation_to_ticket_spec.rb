# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MoveChecklistTicketRelationToTicket, current_user_id: 1, db_strategy: :reset, type: :db_migration do
  let(:ticket_no_checklist)   { create(:ticket) }
  let(:checklist)             { create(:checklist) }
  let(:ticket_with_checklist) { create(:ticket) }

  before do
    ticket_no_checklist
    checklist

    ActiveRecord::Migration[5.0].add_reference :checklists, :ticket, foreign_key: true, null: true, type: :integer
    Checklist.reset_column_information

    checklist.reload.update! ticket_id: ticket_with_checklist.id

    remove_reference :tickets, :checklist
    Ticket.reset_column_information
  end

  it 'keeps ticket-to-checklist relation' do
    migrate

    expect(ticket_with_checklist.reload.checklist).to eq(checklist)
  end
end
