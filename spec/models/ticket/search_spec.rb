# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

  # https://github.com/zammad/zammad/issues/5889
  describe 'Ticket search after user association update', searchindex: true do
    let(:query)        { 'RTF document' }
    let(:group)        { create(:group) }
    let(:customer)     { create(:customer) }
    let(:organization) { create(:organization) }
    let(:ticket)       { create(:ticket, group:, organization:, customer:) }
    let(:article)      { create(:ticket_article, :with_attachment, ticket:, attachment_filename: 'test.rtf') }
    let(:user)         { create(:agent, groups: [group]) }

    before do
      article
      searchindex_model_reload([Ticket, User, Organization])
    end

    it 'does not delete the attachment from the search index' do
      organization.update!(name: 'NewOrgName')
      organization.search_index_update_associations
      SearchIndexBackend.refresh

      expect(Ticket.search(query: query, current_user: user)).to include ticket
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

      # https://github.com/zammad/zammad/issues/5899
      context 'when related user is updated' do
        let(:group)           { create(:group) }
        let(:current_user)    { create(:agent, groups: [group]) }
        let(:user)            { create(:agent_and_customer, firstname: 'OldName') }
        let(:ticket_owner)    { create(:ticket, group:, owner: user) }
        let(:ticket_customer) { create(:ticket, group:, customer: user) }
        let(:query)           { 'NewName' }

        before do
          ticket_owner && ticket_customer

          searchindex_model_reload([Ticket, User])
        end

        it 'updates the search index accordingly' do
          user.update!(firstname: query)
          user.search_index_update_associations
          SearchIndexBackend.refresh

          expect(Ticket.search(query:, current_user:))
            .to include ticket_owner, ticket_customer
        end
      end

      context 'when related organization is updated' do
        let(:group)           { create(:group) }
        let(:current_user)    { create(:agent, groups: [group]) }
        let(:user)            { create(:agent_and_customer, firstname: 'OldName') }
        let(:organization)    { create(:organization, name: 'OldOrgName') }
        let(:customer)        { create(:customer, organization:) }
        let(:ticket)          { create(:ticket, group:, organization:, customer:) }
        let(:query)           { 'NewOrgName' }

        before do
          ticket

          searchindex_model_reload([Ticket, User])
        end

        it 'updates the search index accordingly' do
          organization.update!(name: query)
          organization.search_index_update_associations
          SearchIndexBackend.refresh

          expect(Ticket.search(query:, current_user:))
            .to include ticket
        end
      end
    end

    context 'with db only' do
      include_examples 'search for tickets'
    end
  end

  describe 'Ticket Search: search by id does not work for customers and returns wrong results for users with agent and customer access #6551', searchindex: true do
    let(:group)          { create(:group) }
    let(:customer)       { create(:customer) }
    let(:agent)          { create(:agent, groups: [group]) }
    let(:agent_customer) { create(:agent_and_customer, groups: [create(:group)]) }

    before do
      Setting.set('ticket_hook', 'Ticket-ID: #')
      ticket
      searchindex_model_reload([Ticket])
    end

    def search(query)
      Ticket.search(current_user: user, query: query)
    end

    shared_examples 'search for tickets by id or number' do
      it 'finds the ticket by its id' do
        expect(search("id:#{ticket.id}")).to eq([ticket])
      end

      it 'finds the ticket by an id range' do
        expect(search("id:>#{ticket.id - 1}")).to eq([ticket])
      end

      it 'does not find the ticket by its number in an id range' do
        expect(search("id:>#{ticket.number}")).to eq([])
      end

      it 'finds the ticket by its number' do
        expect(search(ticket.number)).to eq([ticket])
      end

      it 'finds the ticket by its number via field syntax' do
        expect(search("number:#{ticket.number}")).to eq([ticket])
      end
    end

    context 'when user is customer' do
      let(:user)   { customer }
      let(:ticket) { create(:ticket, group:, customer:) }

      include_examples 'search for tickets by id or number'
    end

    context 'when user is agent' do
      let(:user)   { agent }
      let(:ticket) { create(:ticket, group:, customer:) }

      include_examples 'search for tickets by id or number'
    end

    context 'when user is agent and customer' do
      let(:user)   { agent_customer }
      let(:ticket) { create(:ticket, group:, customer: agent_customer) }

      include_examples 'search for tickets by id or number'
    end
  end

  describe 'internal article access' do
    let(:group)          { create(:group) }
    let(:other_group)    { create(:group) }
    let(:organization)   { create(:organization, shared: true, note: organization_note) }
    let(:customer)       { create(:customer, organization:) }
    let(:colleague)      { create(:customer, organization:) }
    let(:owner)          { create(:agent, groups: [group], note: owner_note) }
    let(:agent)          { create(:agent, groups: [group]) }
    let(:agent_customer) { create(:agent_and_customer, groups: [group]) }

    let(:public_term)           { "public#{SecureRandom.hex(8)}" }
    let(:internal_term)         { "internal#{SecureRandom.hex(8)}" }
    let(:title_term)            { "title#{SecureRandom.hex(8)}" }
    let(:foreign_public_term)   { "public#{SecureRandom.hex(8)}" }
    let(:foreign_internal_term) { "internal#{SecureRandom.hex(8)}" }
    let(:tag)                   { "tag#{SecureRandom.hex(8)}" }
    let(:owner_note)            { "note#{SecureRandom.hex(8)}" }
    let(:organization_note)     { "note#{SecureRandom.hex(8)}" }

    let(:ticket)               { create(:ticket, group:, customer:, organization:, owner:) }
    let(:internal_only_ticket) { create(:ticket, group:, customer:, organization:, title: title_term) }
    let(:colleague_ticket)     { create(:ticket, group:, customer: colleague, organization:) }
    let(:foreign_ticket)       { create(:ticket, group: other_group, customer: agent_customer) }

    before do
      create(:ticket_article, ticket:, body: public_term)
      create(:ticket_article, ticket:, body: internal_term, internal: true)
      create(:ticket_article, ticket: internal_only_ticket, body: internal_term, internal: true)
      create(:ticket_article, ticket: colleague_ticket, body: public_term)
      create(:ticket_article, ticket: foreign_ticket, body: foreign_public_term)
      create(:ticket_article, ticket: foreign_ticket, body: foreign_internal_term, internal: true)
      ticket.tag_add(tag, 1)
    end

    def search(query, **params)
      Ticket.search(current_user: user, query: query, **params)
    end

    def condition(name, value)
      { name => { operator: 'contains', value: value } }
    end

    def tag_condition
      { operator: 'AND', conditions: [{ name: 'ticket.tags', operator: 'contains all', value: tag }] }
    end

    shared_examples 'search for tickets' do
      context 'when user is customer' do
        let(:user) { customer }

        it 'finds the tickets by a public article' do
          expect(search(public_term)).to contain_exactly(ticket, colleague_ticket)
        end

        it 'does not find the ticket by an internal article' do
          expect(search(internal_term)).to eq([])
        end

        it 'finds the ticket with internal articles only by its title' do
          expect(search(title_term)).to eq([internal_only_ticket])
        end

        it 'does not find the ticket by a condition on an internal article' do
          expect(search(public_term, condition: condition('article.body', internal_term))).to eq([])
        end

        it 'does not find the ticket by a condition on a tag' do
          expect(search(public_term, condition: tag_condition)).to eq([])
        end

        it 'does not find the ticket by a condition on the owner note' do
          expect(search(public_term, condition: condition('owner.note', owner_note))).to eq([])
        end

        it 'does not find the tickets by a condition on the organization note' do
          expect(search(public_term, condition: condition('organization.note', organization_note))).to eq([])
        end

        it 'finds the ticket by a condition on the owner name' do
          expect(search(public_term, condition: condition('owner.lastname', owner.lastname))).to eq([ticket])
        end

        it 'finds the ticket of the colleague by a condition on the customer name' do
          expect(search(public_term, condition: condition('customer.lastname', colleague.lastname))).to eq([colleague_ticket])
        end
      end

      context 'when user is agent' do
        let(:user) { agent }

        it 'finds the tickets by an internal article' do
          expect(search(internal_term)).to contain_exactly(ticket, internal_only_ticket)
        end

        it 'finds the ticket by a condition on an internal article' do
          expect(search(public_term, condition: condition('article.body', internal_term))).to eq([ticket])
        end

        it 'finds the ticket by a condition on a tag' do
          expect(search(public_term, condition: tag_condition)).to eq([ticket])
        end

        it 'finds the ticket by a condition on the owner note' do
          expect(search(public_term, condition: condition('owner.note', owner_note))).to eq([ticket])
        end

        it 'finds the tickets by a condition on the organization note' do
          expect(search(public_term, condition: condition('organization.note', organization_note))).to contain_exactly(ticket, colleague_ticket)
        end
      end

      context 'when user is agent and customer' do
        let(:user) { agent_customer }

        it 'finds the ticket of an accessible group by an internal article' do
          expect(search(internal_term)).to contain_exactly(ticket, internal_only_ticket)
        end

        it 'finds the own ticket of another group by a public article' do
          expect(search(foreign_public_term)).to eq([foreign_ticket])
        end

        it 'does not find the own ticket of another group by an internal article' do
          expect(search(foreign_internal_term)).to eq([])
        end

        it 'finds the ticket of an accessible group by a condition on an internal article' do
          expect(search(public_term, condition: condition('article.body', internal_term))).to eq([ticket])
        end

        it 'does not find the own ticket of another group by a condition on an internal article' do
          expect(search(foreign_public_term, condition: condition('article.body', foreign_internal_term))).to eq([])
        end
      end
    end

    context 'with elasticsearch', searchindex: true do
      before do
        create(:ticket_article, :with_attachment, ticket:, attachment_filename: 'test.rtf', internal: true)

        searchindex_model_reload([Ticket, User])
      end

      include_examples 'search for tickets'

      context 'when user is customer' do
        let(:user) { customer }

        it 'does not find the ticket by an internal article via field syntax' do
          expect(search("article.body:#{internal_term}")).to eq([])
        end

        it 'does not find the ticket by an internal attachment' do
          expect(search('RTF document')).to eq([])
        end

        it 'does not find the ticket by a tag' do
          expect(search(tag)).to eq([])
        end

        it 'does not find the ticket by a tag via field syntax' do
          expect(search("tags:#{tag}")).to eq([])
        end

        it 'does not exclude the ticket by negating an internal article' do
          expect(search("#{public_term} -#{internal_term}")).to contain_exactly(ticket, colleague_ticket)
        end

        it 'finds the ticket by a public article via field syntax' do
          expect(search("article.body:#{public_term}")).to contain_exactly(ticket, colleague_ticket)
        end

        it 'finds the ticket by a visible attribute via field syntax' do
          expect(search("title:#{title_term}")).to eq([internal_only_ticket])
        end

        it 'finds the tickets via operators and grouping' do
          expect(search("(#{public_term} OR #{title_term}) AND NOT #{tag}")).to contain_exactly(ticket, internal_only_ticket, colleague_ticket)
        end

        it 'does not find the ticket of the colleague by their email' do
          expect(search(colleague.email)).to eq([])
        end

        it 'does not find the ticket of the colleague by their email via field syntax' do
          expect(search("customer.email:#{colleague.email.split('@').first}*")).to eq([])
        end

        it 'finds the ticket of the colleague by their name' do
          expect(search(colleague.lastname)).to eq([colleague_ticket])
        end

        context 'with a custom attribute', db_strategy: :reset do
          let(:value) { "value#{SecureRandom.hex(8)}" }

          before do
            create(:object_manager_attribute_text, name: 'contract_number')
            ObjectManager::Attribute.migration_execute
            ticket.reload.update!(contract_number: value)

            searchindex_model_reload([Ticket])
          end

          it 'does not find the ticket by a hidden attribute via field wildcard' do
            expect(search("\\*number:#{value}")).to eq([])
          end
        end
      end

      context 'when user is agent' do
        let(:user) { agent }

        it 'finds the tickets by an internal article via field syntax' do
          expect(search("article.body:#{internal_term}")).to contain_exactly(ticket, internal_only_ticket)
        end

        it 'finds the ticket by an internal attachment' do
          expect(search('RTF document')).to eq([ticket])
        end

        it 'finds the ticket by a tag' do
          expect(search(tag)).to eq([ticket])
        end

        it 'finds the ticket of the colleague by their email' do
          expect(search(colleague.email)).to eq([colleague_ticket])
        end
      end
    end

    context 'with db only' do
      include_examples 'search for tickets'
    end
  end
end
