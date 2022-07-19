# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'HasSearchIndexBackend', type: :model, searchindex: true, performs_jobs: true do
  before do
    configure_elasticsearch(required: true, rebuild: true) do
      article.ticket.search_index_update_backend
      organization.search_index_update_backend
    end
  end

  describe 'Updating referenced data between ticket and organizations' do
    let(:organization) { create(:organization, name: 'Tomato42') }
    let(:user)         { create(:customer, organization: organization) }
    let(:ticket)       { create(:ticket, customer: user) }
    let(:article) do
      article = create(:ticket_article, ticket_id: ticket.id)

      create(:store,
             object:   'Ticket::Article',
             o_id:     article.id,
             data:     File.binread(Rails.root.join('test/data/elasticsearch/es-normal.txt')),
             filename: 'es-normal.txt')

      article
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

    it 'does exclude Ticket for bulk action updates' do
      expect(organization).not_to be_search_index_indexable_bulk_updates(Ticket)
    end

    it 'does include organization_id as relevant search index attribute' do
      expect(Ticket).to be_search_index_attribute_relevant('organization_id')
    end

    it 'does exclude updated_by as relevant search index attribute' do
      expect(Ticket).not_to be_search_index_attribute_relevant('updated_by_id')
    end
  end
end
