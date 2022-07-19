# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'HasSearchIndexBackend', type: :model, searchindex: true do
  before do
    configure_elasticsearch(required: true, rebuild: true) do
      user.search_index_update_backend
      organization.search_index_update_backend
    end
  end

  describe 'Updating referenced data between user and organizations' do
    let(:organization) { create(:organization, name: 'Tomato42') }
    let(:user)         { create(:customer, organization: organization) }

    it 'finds added users' do
      result = SearchIndexBackend.search('organization.name:Tomato42', 'User', sort_by: ['updated_at'], order_by: ['desc'])
      expect(result).to eq([{ id: user.id.to_s, type: 'User' }])
    end

    context 'when renaming the organization' do
      before do
        organization.update(name: 'Cucumber43 Ltd.')
        organization.search_index_update_associations
        SearchIndexBackend.refresh
      end

      it 'finds added users by organization name in sub hash' do
        result = SearchIndexBackend.search('organization.name:Cucumber43', 'User', sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([{ id: user.id.to_s, type: 'User' }])
      end

      it 'finds added users by organization name' do
        result = SearchIndexBackend.search('Cucumber43', 'User', sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([{ id: user.id.to_s, type: 'User' }])
      end
    end

    it 'does include User for bulk action updates' do
      expect(organization).to be_search_index_indexable_bulk_updates(User)
    end
  end
end
