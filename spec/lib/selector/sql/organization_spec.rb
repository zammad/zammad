# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Selector::Sql, 'organization' do
  describe 'organization.members_existing' do
    let(:user_1)                { create(:agent, organization: Organization.first) }
    let(:organization_unused_1) { create(:organization) }
    let(:organization_unused_2) { create(:organization) }
    let(:organization_unused_3) { create(:organization) }

    before do
      user_1
      Organization.first.touch
      organization_unused_1
      organization_unused_2
      organization_unused_3
    end

    it 'does find the organizations with users', :aggregate_failures do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'organization.id',
            operator: 'is',
            value:    [Organization.first.id.to_s, organization_unused_1.id.to_s, organization_unused_2.id.to_s, organization_unused_3.id.to_s],
          },
          {
            name:     'organization.members_existing',
            operator: 'is',
            value:    'true',
          },
        ]
      }

      count, = Organization.selectors(condition)
      expect(count).to eq(1)
    end

    it 'does find the organizations with no users', :aggregate_failures do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'organization.id',
            operator: 'is',
            value:    [Organization.first.id.to_s, organization_unused_1.id.to_s, organization_unused_2.id.to_s, organization_unused_3.id.to_s],
          },
          {
            name:     'organization.members_existing',
            operator: 'is',
            value:    'false',
          },
        ]
      }

      count, = Organization.selectors(condition)
      expect(count).to eq(3)
    end
  end
end
