# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Article::AddsMetadataGeneral do
  let(:agent) { create(:agent) }

  context 'when Agent creates Article' do
    shared_examples 'not including email in from' do |factory|
      subject(:article) { create(:ticket_article, factory, ticket: ticket, created_by_id: agent.id, updated_by_id: agent.id ) }

      let(:ticket) { create(:ticket) }
      let!(:agent) { create(:agent, groups: [ticket.group]) }

      it "doesn't include email in from" do
        expect(article.from).not_to include agent.email
      end
    end

    it_behaves_like 'not including email in from', :outbound_phone
    it_behaves_like 'not including email in from', :outbound_web

    context 'when as Customer' do
      subject(:article) { create(:ticket_article, :inbound_phone, ticket: ticket) }

      let(:customer) { agent }
      let(:ticket) { create(:ticket, customer_id: customer.id) }

      it 'includes email in from' do
        expect(article.from).not_to include agent.email
      end
    end
  end
end
