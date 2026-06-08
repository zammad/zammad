# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Bulk::Selector do
  let(:group)   { create(:group) }
  let(:user)    { create(:agent, groups: [group]) }
  let(:tickets) { create_list(:ticket, 3, group:) }

  describe '#execute' do
    context 'when passing ticket IDs' do
      subject(:service_result) { described_class.with_current_user(user).execute(selector:) }

      let(:selector) { { entity_ids: tickets.pluck(:id) } }

      it 'returns the selected tickets' do
        expect(service_result).to eq(tickets.pluck(:id))
      end

      it 'limits the number of returned ticket IDs to MAX_TICKET_IDS' do
        stub_const("#{described_class}::MAX_TICKET_IDS", 2)
        expect(service_result.count).to eq(2)
      end
    end

    context 'when passing an overview' do
      subject(:service_result) { described_class.with_current_user(user).execute(selector: { overview: }) }

      let(:overview) { create(:overview) }

      before do
        allow(Ticket::Overviews)
          .to receive(:tickets_for_overview)
          .with(overview, user)
          .and_return(Ticket.where(id: tickets))
      end

      it 'returns the overview contents' do
        expect(service_result).to eq(tickets.pluck(:id))
      end

      it 'limits the number of returned ticket IDs to MAX_TICKET_IDS' do
        stub_const("#{described_class}::MAX_TICKET_IDS", 2)
        expect(service_result.count).to eq(2)
      end
    end

    context 'when passing a search query', searchindex: true do
      subject(:service_result) { described_class.with_current_user(user).execute(selector: { search_query: query }) }

      let(:query) { group.name }

      before do
        tickets
        searchindex_model_reload([Ticket])
      end

      it 'returns search result' do
        expect(service_result).to match_array(tickets.pluck(:id).map(&:to_s))
      end

      it 'limits the number of returned ticket IDs to MAX_TICKET_IDS', searchindex: true do
        stub_const("#{described_class}::MAX_TICKET_IDS", 2)
        expect(service_result.count).to eq(2)
      end
    end
  end
end
