# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Bulk::Selector do
  let(:group)    { create(:group) }
  let(:user)     { create(:agent, groups: [group]) }
  let(:tickets)  { create_list(:ticket, 3, group:) }
  let(:instance) { described_class.new(user:, selector:) }

  describe '#execute' do
    context 'when passing ticket IDs' do
      let(:selector) { { entity_ids: tickets.pluck(:id) } }

      it 'returns the selected tickets' do
        expect(instance.execute).to eq(tickets.pluck(:id))
      end

      it 'limits the number of returned ticket IDs to MAX_TICKET_IDS' do
        stub_const("#{described_class}::MAX_TICKET_IDS", 2)
        expect(instance.execute.count).to eq(2)
      end
    end

    context 'when passing an overview' do
      let(:overview) { create(:overview) }
      let(:selector) { { overview: } }

      before do
        allow(Ticket::Overviews)
          .to receive(:tickets_for_overview)
          .with(overview, user)
          .and_return(Ticket.where(id: tickets))
      end

      it 'returns the overview contents' do
        expect(instance.execute).to eq(tickets.pluck(:id))
      end

      it 'limits the number of returned ticket IDs to MAX_TICKET_IDS' do
        stub_const("#{described_class}::MAX_TICKET_IDS", 2)
        expect(instance.execute.count).to eq(2)
      end
    end

    context 'when passing a search query', searchindex: true do
      let(:query) { group.name }
      let(:selector) { { search_query: query } }

      before do
        tickets
        searchindex_model_reload([Ticket])
      end

      it 'returns search result' do
        expect(instance.execute).to match_array(tickets.pluck(:id).map(&:to_s))
      end

      it 'limits the number of returned ticket IDs to MAX_TICKET_IDS', searchindex: true do
        stub_const("#{described_class}::MAX_TICKET_IDS", 2)
        expect(instance.execute.count).to eq(2)
      end
    end
  end
end
