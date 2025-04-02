# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddChecklistItemTicketAssociation, db_strategy: :reset, type: :db_migration do
  let(:migration) { described_class.new }

  before do
    remove_reference :checklist_items, :ticket
    Checklist::Item.reset_column_information
  end

  describe '#up' do
    it 'adds a reference to checklist_items' do
      migrate

      expect(Checklist::Item.new.ticket_id).to be_nil
    end
  end
end
