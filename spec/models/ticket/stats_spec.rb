# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    # https://github.com/zammad/zammad/issues/5600
    it 'returns empty results if user does not have access to any tickets' do
      user_sans_permissions = create(:user).tap { it.update! roles: [create(:role)] }

      instance = described_class.new(current_user: user_sans_permissions, user_id: customer_other.id, organization_id: organization.id, assets: {})

      expect(instance.list_stats).to include(
        user:         {
          closed_ids:     [],
          open_ids:       [],
          volume_by_year: [
            { closed: 0, created: 0, month: 7, text: 'July', year: 2019 },
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
          closed_ids:     [],
          open_ids:       [],
          volume_by_year: [
            { closed: 0, created: 0, month: 7, text: 'July', year: 2019 },
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
        }
      )
    end

    # https://github.com/zammad/zammad/issues/5865
    context 'when the ticket is created just before the new month' do
      before do
        ticket_open_2.update!(created_at: Time.zone.parse('2019-06-30 23:00'))
        Setting.set('timezone_default', timezone)
      end

      context 'when time zome is ahead of UTC' do
        let(:timezone) { 'Asia/Tokyo' }

        it 'returns tickets according to Zammad time zone' do
          instance = described_class.new(current_user: agent, user_id: customer.id, assets: {})

          expect(instance.list_stats).to include(
            organization: {},
            user:         {
              closed_ids:     [ticket_closed.id],
              open_ids:       [ticket_open_2.id, ticket_open.id],
              volume_by_year: [
                { closed: 0, created: 1, month: 7, text: 'July', year: 2019 },
                { closed: 1, created: 1, month: 6, text: 'June', year: 2019 },
                { closed: 0, created: 0, month: 5, text: 'May', year: 2019 },
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

      context 'when time zone is behind UTC' do
        let(:timezone) { 'America/New_York' }

        it 'returns tickets according to Zammad time zone' do
          instance = described_class.new(current_user: agent, user_id: customer.id, assets: {})

          expect(instance.list_stats).to include(
            organization: {},
            user:         {
              closed_ids:     [ticket_closed.id],
              open_ids:       [ticket_open_2.id, ticket_open.id],
              volume_by_year: [
                { closed: 0, created: 0, month: 7, text: 'July', year: 2019 },
                { closed: 1, created: 2, month: 6, text: 'June', year: 2019 },
                { closed: 0, created: 0, month: 5, text: 'May', year: 2019 },
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
  end
end
