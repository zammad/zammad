# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Selector::Base, 'organization', searchindex: true do
  describe 'Basic tests' do
    let(:organization_1) { create(:organization) }
    let(:organization_2) { create(:organization) }
    let(:organization_3) { create(:organization) }

    before do
      organization_1 && organization_2 && organization_3
      searchindex_model_reload([Organization])
    end

    it 'does find organizations by name', :aggregate_failures do
      condition = {
        operator:   'OR',
        conditions: [
          {
            name:     'organization.name',
            operator: 'contains',
            value:    organization_1.name,
          },
          {
            name:     'organization.name',
            operator: 'contains',
            value:    organization_2.name,
          },
          {
            name:     'organization.name',
            operator: 'contains',
            value:    organization_3.name,
          },
        ]
      }

      count, = Organization.selectors(condition)
      expect(count).to eq(3)

      result = SearchIndexBackend.selectors('Organization', condition)
      expect(result[:count]).to eq(3)
    end
  end
end
