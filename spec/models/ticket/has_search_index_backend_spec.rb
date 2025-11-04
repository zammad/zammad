# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'HasSearchIndexBackend', performs_jobs: true, searchindex: true, type: :model do
  describe 'Updating referenced data between ticket and organizations' do
    let(:organization) { create(:organization, name: 'Tomato42') }
    let(:user)         { create(:customer, organization: organization) }
    let(:ticket)       { create(:ticket, customer: user) }
    let(:article) do
      article = create(:ticket_article, ticket_id: ticket.id)

      create(:store,
             object:   'Ticket::Article',
             o_id:     article.id,
             data:     Rails.root.join('test/data/elasticsearch/es-normal.txt').binread,
             filename: 'es-normal.txt')

      article
    end

    before do
      article && organization

      searchindex_model_reload([Ticket, Organization])
    end

    it 'finds added tickets' do
      result = SearchIndexBackend.search('organization.name:Tomato42', 'Ticket', sort_by: ['updated_at'], order_by: ['desc'])
      expect(result).to eq([{ id: ticket.id.to_s, type: 'Ticket' }])
    end

    it 'finds added ticket article attachments' do
      result = SearchIndexBackend.search('text66', 'Ticket', sort_by: ['updated_at'], order_by: ['desc'])
      expect(result).to eq([{ id: ticket.id.to_s, type: 'Ticket' }])
    end

    context 'when renaming the organization' do
      before do
        organization.update(name: 'Cucumber43 Ltd.')
        organization.search_index_update_associations
        perform_enqueued_jobs
        SearchIndexBackend.refresh
      end

      it 'finds added tickets by organization name in sub hash' do
        result = SearchIndexBackend.search('organization.name:Cucumber43', 'Ticket', sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([{ id: ticket.id.to_s, type: 'Ticket' }])
      end

      it 'finds added tickets by organization name' do
        result = SearchIndexBackend.search('Cucumber43', 'Ticket', sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([{ id: ticket.id.to_s, type: 'Ticket' }])
      end

      it 'still finds attachments' do
        result = SearchIndexBackend.search('text66', 'Ticket', sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([{ id: ticket.id.to_s, type: 'Ticket' }])
      end
    end

    it 'does return organization_id as referenced indexable attribute' do
      result = organization.search_index_indexable_attributes(Ticket)
      expect(result).to include({ name: 'organization_id', ref_name: 'organization' })
    end

    it 'does not return updated_by_id as referenced indexable attribute' do
      result = user.search_index_indexable_attributes(Ticket)
      expect(result).not_to include({ name: 'updated_by_id', ref_name: 'updated_by' })
    end

    it 'does include organization_id as relevant search index attribute' do
      expect(Ticket).to be_search_index_attribute_relevant('organization_id')
    end

    it 'does exclude updated_by as relevant search index attribute' do
      expect(Ticket).not_to be_search_index_attribute_relevant('updated_by_id')
    end
  end

  %w[group priority state].each do |relation|
    describe "Updating referenced data between ticket and #{relation}" do
      let(:user)   { create(:customer) }
      let(:ticket) { create(:ticket, customer: user) }

      before do
        ticket.send(relation).update!(name: 'NewTestPhrase')
        perform_enqueued_jobs
        SearchIndexBackend.refresh
      end

      it 'finds ticket after relation update' do
        query  = "#{relation}.name:NewTestPhrase"
        result = Ticket.search(current_user: user, query:)

        expect(result).to eq([ticket])
      end
    end
  end

  describe 'Include Checklist and items in search index', current_user_id: 1 do
    let(:user) { create(:agent, groups: [ticket.group]) }
    let(:ticket)         { create(:ticket) }
    let(:checklist)      { create(:checklist, ticket:) }
    let(:checklist_item) { create(:checklist_item, checklist:) }

    before do
      checklist_item
      perform_enqueued_jobs
      SearchIndexBackend.refresh
    end

    it 'finds the ticket by checklist name' do
      result = Ticket.search(current_user: user, query: checklist.name)

      expect(result).to eq([ticket])
    end

    it 'finds the ticket by checklist item text' do
      result = Ticket.search(current_user: user, query: checklist_item.text)

      expect(result).to eq([ticket])
    end
  end

  describe 'Updating group settings causes huge numbers of delayed jobs #4306', performs_jobs: false do
    let(:ticket) { create(:ticket, customer: create(:customer, :with_org)) }

    before do
      ticket
      Delayed::Job.destroy_all
    end

    it 'does not create any jobs if nothing has changed' do
      expect { ticket.update(title: ticket.title) }.not_to change(Delayed::Job, :count)
    end

    it 'does not create any jobs for the organization if the organization has not changed at the ticket' do
      ticket.update(title: SecureRandom.uuid)
      expect(Delayed::Job.where("handler LIKE '%SearchIndexJob%' AND handler LIKE '%Organization%'").count).to eq(0)
    end

    it 'does create jobs for the organization if the organization has changed at the ticket' do
      ticket.update(customer: create(:customer, :with_org))
      expect(Delayed::Job.where("handler LIKE '%SearchIndexJob%' AND handler LIKE '%Organization%'").count).to be > 0
    end
  end

  describe 'Search doesnt show tickets belonging to secondary organization #4425' do
    let(:organization_a) { create(:organization, shared: true) }
    let(:organization_b) { create(:organization, shared: false) }

    let(:customer_a) { create(:customer, :with_org, organizations: [organization_a, organization_b]) }
    let(:customer_b) { create(:customer, :with_org, organizations: [organization_a, organization_b]) }

    let(:ticket_customer_a_shared) do
      ticket = create(:ticket, title: 'findme', customer: customer_a, organization: organization_a)
      create(:ticket_article, ticket: ticket)
      ticket
    end
    let(:ticket_customer_a_nonshared) do
      ticket = create(:ticket, title: 'findme', customer: customer_a, organization: organization_b)
      create(:ticket_article, ticket: ticket)
      ticket
    end
    let(:ticket_customer_b_shared) do
      ticket = create(:ticket, title: 'findme', customer: customer_b, organization: organization_a)
      create(:ticket_article, ticket: ticket)
      ticket
    end
    let(:ticket_customer_b_nonshared) do
      ticket = create(:ticket, title: 'findme', customer: customer_b, organization: organization_b)
      create(:ticket_article, ticket: ticket)
      ticket
    end

    before do
      ticket_customer_a_shared
      ticket_customer_a_nonshared
      ticket_customer_b_shared
      ticket_customer_b_nonshared
      searchindex_model_reload([Ticket, User, Organization])
    end

    context 'with ES' do
      it 'customer does find shared tickets', :aggregate_failures do
        result = Ticket.search(
          current_user: customer_a,
          query:        'findme',
          full:         true,
        )

        expect(result).to include(ticket_customer_a_shared)
        expect(result).to include(ticket_customer_a_nonshared)
        expect(result).to include(ticket_customer_b_shared)
        expect(result).not_to include(ticket_customer_b_nonshared)
      end
    end

    context 'with DB', searchindex: false do
      it 'customer does find shared tickets', :aggregate_failures do
        result = Ticket.search(
          current_user: customer_a,
          query:        'findme',
          full:         true,
        )

        expect(result).to include(ticket_customer_a_shared)
        expect(result).to include(ticket_customer_a_nonshared)
        expect(result).to include(ticket_customer_b_shared)
        expect(result).not_to include(ticket_customer_b_nonshared)
      end
    end
  end
end
