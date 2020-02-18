RSpec.shared_examples 'CanLookupSearchIndexAttributes' do
  describe '.search_index_value_by_attribute' do
    it 'returns hash of data' do
      organization = create(:organization, name: 'Tomato42', note: 'special recipe')
      user         = create(:agent_user, organization: organization)

      value = user.search_index_value_by_attribute('organization_id')
      expect_value = { 'name' => 'Tomato42', 'note' => 'special recipe' }
      expect(value).to be_a_kind_of(Hash)
      expect(value).to eq(expect_value)
    end
  end

  describe '.search_index_value' do
    it 'returns correct value' do
      organization = create(:organization, name: 'Tomato42', note: 'special recipe')

      value = organization.search_index_value
      expect_value = { 'name' => 'Tomato42', 'note' => 'special recipe' }
      expect(value).to be_a_kind_of(Hash)
      expect(value).to eq(expect_value)
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
