# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
end
