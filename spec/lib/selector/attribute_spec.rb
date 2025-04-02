# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket::Selector', db_strategy: :reset, searchindex: true do
  before do
    Ticket.destroy_all
    attribute
    tickets
    searchindex_model_reload([Ticket])
  end

  let(:agent) { create(:agent, groups: [Group.first]) }
  let(:attribute) do
    attribute = create(:object_manager_attribute_text)
    ObjectManager::Attribute.migration_execute

    attribute
  end
  let(:tickets) do
    tickets = create_list(:ticket, 10, group: Group.first)
    tickets.each_with_index do |ticket, index|
      ticket[attribute.name] = index.odd? ? '1st value' : '2nd value'
      ticket.save!
    end
  end
  let(:condition) do
    {
      "ticket.#{attribute.name}" => {
        operator: 'is',
        value:    '1st value',
      },
    }
  end

  describe 'select by condition attribute' do
    context 'when using the ticket selector' do
      it 'is successful' do
        ticket_count, = Ticket.selectors(condition, limit: 100)
        expect(ticket_count).to eq(5)
      end
    end

    context 'when using the search index backend' do
      it 'is successful' do
        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(5)
      end
    end
  end
end
