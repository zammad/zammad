# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'HasSearchIndexBackend', searchindex: true, type: :model do
  describe 'Updating referenced data between user and organizations' do
    let(:organization) { create(:organization, name: 'Tomato42') }
    let(:user)         { create(:customer, organization: organization) }

    before do
      user && organization

      searchindex_model_reload([User, Organization])
    end

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
  end

  describe 'Updating group settings causes huge numbers of delayed jobs #4306' do
    let(:user) { create(:user) }

    before do
      user
      Delayed::Job.destroy_all
    end

    it 'does not create any jobs if nothing has changed' do
      expect { user.update(firstname: user.firstname) }.not_to change(Delayed::Job, :count)
    end
  end

  describe 'Search doesnt show tickets belonging to secondary organization #4425' do
    let(:user) { create(:user, organization: create(:organization), organizations: [create(:organization, name: SecureRandom.uuid)]) }

    before do
      user
      searchindex_model_reload([User, Organization])
    end

    it 'does find user by secondary organization' do
      result = SearchIndexBackend.search(user.organizations.first.name, 'User', sort_by: ['updated_at'], order_by: ['desc'])
      expect(result).to eq([{ id: user.id.to_s, type: 'User' }])
    end
  end
end
