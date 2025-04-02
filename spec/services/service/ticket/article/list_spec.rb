# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Article::List do
  subject(:service) { described_class.new(current_user: user) }

  let(:ticket)   { create(:ticket) }
  let(:articles) { create_list(:ticket_article, 3, ticket: ticket) }

  describe '#execute' do
    before do
      articles.first.update!(internal: true)
    end

    context 'when user has read access (agent)' do
      let(:user) { create(:agent, groups: [ticket.group]) }

      it 'returns all articles' do
        expect(service.execute(ticket: ticket)).to eq(articles)
      end
    end

    context 'when user has no read access (agent)' do
      let(:user) { create(:agent) }

      it 'returns all articles' do
        expect(service.execute(ticket: ticket)).to eq(articles[1..])
      end
    end

    context 'when user has no read access (customer)' do
      let(:user) { create(:customer) }

      before do
        ticket.update!(customer: user)
      end

      it 'returns only public articles' do
        expect(service.execute(ticket: ticket)).to eq(articles[1..])
      end
    end
  end
end
