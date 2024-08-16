# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddChecklistItemTicketAssociation, db_strategy: :reset, type: :migration do
  let(:migration) { described_class.new }

  before do
    %i[checklist_template_items checklist_templates checklist_items checklists].each do |table|
      ActiveRecord::Migration[5.0].drop_table table
    end
    AddChecklists.new.up
  end

  describe '#up' do
    it 'adds a reference to checklist_items' do
      migration.up

      migrated = ActiveRecord::Base.connection.foreign_keys('checklist_items').any? do |fk|
        fk.options[:column] == 'ticket_id'
      end
      expect(migrated).to be true
    end
  end
end
