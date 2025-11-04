# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Search do
  describe 'Duplicate results in search #3876' do
    let(:search)   { SecureRandom.uuid }
    let(:ticket)   { create(:ticket, group: Group.first) }
    let(:articles) { create_list(:ticket_article, 3, ticket: ticket, body: search) }
    let(:agent)    { create(:agent, groups: Group.all) }

    before do
      articles
    end

    it 'does not show up the same ticket twice if no elastic search is configured' do
      expect(Ticket.search(current_user: agent, query: search)).to eq([ticket])
    end
  end

  describe 'Missing wildcard search on fulltext search #5558', searchindex: true do
    let(:search)   { SecureRandom.uuid }
    let(:ticket)   { create(:ticket, group: Group.first) }
    let(:agent)    { create(:agent, groups: Group.all) }

    before do
      ticket
      searchindex_model_reload([Ticket])
    end

    it 'does not show up the same ticket twice if no elastic search is configured' do
      expect(Ticket.search(current_user: agent, query: '(state.name:new OR state.name:open) AND NOT customer.organization_id:* AND owner_id:1')).to eq([ticket])
    end
  end

  describe 'Add support for optional Elasticsearch asciifolding analyzer #5537', searchindex: true do
    let(:search)       { 'Ružovučký' }
    let(:search_fuzzy) { 'ruzovucky' }
    let!(:ticket)      { create(:ticket, title: 'Ružovučký koníček a sôvä spia', group: Group.first) }
    let(:agent)        { create(:agent, groups: Group.all) }

    before do
      searchindex_model_reload([Ticket])
    end

    it 'does find the ticket via asciifolding', :aggregate_failures do
      expect(Ticket.search(current_user: agent, query: search)).to eq([ticket])
      expect(Ticket.search(current_user: agent, query: search_fuzzy)).to eq([ticket])
    end

    context 'when disabled' do
      before do
        Setting.set('es_asciifolding', false)
        SearchIndexBackend.drop_index([Ticket])
        SearchIndexBackend.create_index([Ticket])
        searchindex_model_reload([Ticket])
      end

      it 'does not find the ticket without asciifolding', :aggregate_failures do
        expect(Ticket.search(current_user: agent, query: search)).to eq([ticket])
        expect(Ticket.search(current_user: agent, query: search_fuzzy)).to eq([])
      end
    end
  end

  describe 'Language detection mechanism #5476', searchindex: true do
    let(:ticket)  { create(:ticket, group: Group.first) }
    let(:article) { create(:ticket_article, ticket: ticket, detected_language: 'de') }
    let(:agent)   { create(:agent, groups: Group.all) }

    before do
      article
      searchindex_model_reload([Ticket])
    end

    shared_examples 'finding the ticket by its article attribute' do
      it 'finds the ticket by its article attribute' do
        expect(Ticket.search(current_user: agent, query: search)).to eq([ticket])
      end
    end

    context 'with language code' do
      let(:search) { 'article.detected_language:de' }

      it_behaves_like 'finding the ticket by its article attribute'
    end

    context 'with language name' do
      let(:search) { 'article.detected_language_name:german' }

      it_behaves_like 'finding the ticket by its article attribute'
    end
  end

  describe 'Tickets are not found via the search using the complete ticket hook #5659', searchindex: true do
    let(:ticket) { create(:ticket, group: Group.first) }
    let(:agent) { create(:agent, groups: Group.all) }

    before do
      ticket
      searchindex_model_reload([Ticket])
    end

    it 'does find the ticket by hook' do
      expect(Ticket.search(current_user: agent, query: "#{Setting.get('ticket_hook')}#{ticket.number}")).to eq([ticket])
    end
  end

  describe 'access check' do
    let(:shared) { true }
    let(:organization)   { create(:organization, shared:) }
    let(:group)          { create(:group) }
    let(:agent)          { create(:agent, groups: [group]) }
    let(:customer)       { create(:customer, organization: organization) }
    let(:other_customer) { create(:customer, organization: create(:organization), organizations: [organization]) }
    let(:ticket_1)       { create(:ticket, title: 'search 1', group:, organization:, customer:) }
    let(:ticket_2)       { create(:ticket, title: 'search 2', group:, organization:, customer: other_customer) }
    let(:ticket_3)       { create(:ticket, title: 'search 3') }
    let(:ticket_4)       { create(:ticket, title: 'search 4', owner: agent) }

    before do
      [ticket_1, ticket_2, ticket_3, ticket_4].each do |ticket|
        create(:ticket_article, ticket: ticket)
      end
    end

    shared_examples 'search for tickets' do
      let(:results) { Ticket.search(current_user: user, query: 'search') }

      context 'when user is agent' do
        let(:user) { agent }

        it 'finds accessible tickets' do
          expect(results).to contain_exactly(ticket_1, ticket_2)
        end
      end

      context 'when user is customer' do
        let(:user) { customer }

        context 'when organization is shared' do
          it 'finds accessible tickets' do
            expect(results).to contain_exactly(ticket_1, ticket_2)
          end
        end

        context 'when organization is not shared' do
          let(:shared) { false }

          it 'finds accessible tickets' do
            expect(results).to contain_exactly(ticket_1)
          end
        end
      end
    end

    context 'with elasticsearch', searchindex: true do
      before do
        searchindex_model_reload([Ticket, User, Organization])
      end

      include_examples 'search for tickets'
    end

    context 'with db only' do
      include_examples 'search for tickets'
    end
  end
end
