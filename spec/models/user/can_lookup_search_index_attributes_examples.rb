# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'CanLookupSearchIndexAttributes' do
  describe '.search_index_value_by_attribute' do
    it 'returns search index value for attribute' do
      organization = create(:organization, name: 'Tomato42', note: 'special recipe')
      user         = create(:agent, organization: organization)

      value = user.search_index_value_by_attribute('organization_id')
      expect(value['name']).to eq('Tomato42')
    end
  end

  describe '.search_index_attribute_ref_name' do
    it 'returns correct value' do
      attribute_ref_name = User.search_index_attribute_ref_name('organization_id')
      expect(attribute_ref_name).to eq('organization')
    end
  end

  describe '.search_index_attribute_ignored?' do
    it 'returns correct value' do
      ignored = User.search_index_attribute_ignored?('password')
      expect(ignored).to be true
    end
  end
end
