# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Stats do
  let(:organization) { create(:organization) }
  let(:group)        { create(:group) }

  let(:customer) { create(:customer, organization:) }
  let(:customer_other) { create(:customer, organization:) }

  let(:agent) { create(:agent, groups: [group]) }

  let(:ticket_open)                { create(:ticket, group:, customer:, organization:, state_name: 'open') }
  let(:ticket_open_2)              { create(:ticket, group:, customer:, organization:, state_name: 'open') }
  let(:ticket_closed)              { create(:ticket, group:, customer:, organization:, state_name: 'closed') }
  let(:ticket_other_user_same_org) { create(:ticket, group:, customer: customer_other, organization:, state_name: 'open') }

  before do
    travel_to(Time.zone.parse('2019-01-11 12:00'))
    ticket_open
    travel 4.months
    ticket_open_2
    travel 1.month
    ticket_closed
    travel 1.month
    ticket_other_user_same_org
  end

  describe '#list_stats' do
    it 'returns tickets by agent' do
      instance = described_class.new(current_user: agent, user_id: customer.id, assets: {})

      expect(instance.list_stats).to include(
        organization: {},
        user:         {
          closed_ids:     [ticket_closed.id],
          open_ids:       [ticket_open_2.id, ticket_open.id],
          volume_by_year: [
            { closed: 0, created: 0, month: 7, text: 'July', year: 2019 },
            { closed: 1, created: 1, month: 6, text: 'June', year: 2019 },
            { closed: 0, created: 1, month: 5, text: 'May', year: 2019 },
            { closed: 0, created: 0, month: 4, text: 'April', year: 2019 },
            { closed: 0, created: 0, month: 3, text: 'March', year: 2019 },
            { closed: 0, created: 0, month: 2, text: 'February', year: 2019 },
            { closed: 0, created: 1, month: 1, text: 'January', year: 2019 },
            { closed: 0, created: 0, month: 12, text: 'December', year: 2018 },
            { closed: 0, created: 0, month: 11, text: 'November', year: 2018 },
            { closed: 0, created: 0, month: 10, text: 'October', year: 2018 },
            { closed: 0, created: 0, month: 9, text: 'September', year: 2018 },
            { closed: 0, created: 0, month: 8, text: 'August', year: 2018 }
          ]
        }
      )
    end

    it 'returns tickets by organization' do
      instance = described_class.new(current_user: agent, organization_id: organization.id, assets: {})

      expect(instance.list_stats).to include(
        user:         {},
        organization: {
          closed_ids:     [ticket_closed.id],
          open_ids:       [ticket_other_user_same_org.id, ticket_open_2.id, ticket_open.id],
          volume_by_year: [
            { closed: 0, created: 1, month: 7, text: 'July', year: 2019 },
            { closed: 1, created: 1, month: 6, text: 'June', year: 2019 },
            { closed: 0, created: 1, month: 5, text: 'May', year: 2019 },
            { closed: 0, created: 0, month: 4, text: 'April', year: 2019 },
            { closed: 0, created: 0, month: 3, text: 'March', year: 2019 },
            { closed: 0, created: 0, month: 2, text: 'February', year: 2019 },
            { closed: 0, created: 1, month: 1, text: 'January', year: 2019 },
            { closed: 0, created: 0, month: 12, text: 'December', year: 2018 },
            { closed: 0, created: 0, month: 11, text: 'November', year: 2018 },
            { closed: 0, created: 0, month: 10, text: 'October', year: 2018 },
            { closed: 0, created: 0, month: 9, text: 'September', year: 2018 },
            { closed: 0, created: 0, month: 8, text: 'August', year: 2018 }
          ]
        }
      )
    end

    it 'returns tickets by user and organization' do
      instance = described_class.new(current_user: agent, user_id: customer_other.id, organization_id: organization.id, assets: {})

      expect(instance.list_stats).to include(
        user:         {
          closed_ids:     [],
          open_ids:       [ticket_other_user_same_org.id],
          volume_by_year: [
            { closed: 0, created: 1, month: 7, text: 'July', year: 2019 },
            { closed: 0, created: 0, month: 6, text: 'June', year: 2019 },
            { closed: 0, created: 0, month: 5, text: 'May', year: 2019 },
            { closed: 0, created: 0, month: 4, text: 'April', year: 2019 },
            { closed: 0, created: 0, month: 3, text: 'March', year: 2019 },
            { closed: 0, created: 0, month: 2, text: 'February', year: 2019 },
            { closed: 0, created: 0, month: 1, text: 'January', year: 2019 },
            { closed: 0, created: 0, month: 12, text: 'December', year: 2018 },
            { closed: 0, created: 0, month: 11, text: 'November', year: 2018 },
            { closed: 0, created: 0, month: 10, text: 'October', year: 2018 },
            { closed: 0, created: 0, month: 9, text: 'September', year: 2018 },
            { closed: 0, created: 0, month: 8, text: 'August', year: 2018 }
          ]
        },
        organization: {
          closed_ids:     [ticket_closed.id],
          open_ids:       [ticket_other_user_same_org.id, ticket_open_2.id, ticket_open.id],
          volume_by_year: [
            { closed: 0, created: 1, month: 7, text: 'July', year: 2019 },
            { closed: 1, created: 1, month: 6, text: 'June', year: 2019 },
            { closed: 0, created: 1, month: 5, text: 'May', year: 2019 },
            { closed: 0, created: 0, month: 4, text: 'April', year: 2019 },
            { closed: 0, created: 0, month: 3, text: 'March', year: 2019 },
            { closed: 0, created: 0, month: 2, text: 'February', year: 2019 },
            { closed: 0, created: 1, month: 1, text: 'January', year: 2019 },
            { closed: 0, created: 0, month: 12, text: 'December', year: 2018 },
            { closed: 0, created: 0, month: 11, text: 'November', year: 2018 },
            { closed: 0, created: 0, month: 10, text: 'October', year: 2018 },
            { closed: 0, created: 0, month: 9, text: 'September', year: 2018 },
            { closed: 0, created: 0, month: 8, text: 'August', year: 2018 }
          ]
        }
      )
    end
  end
end
