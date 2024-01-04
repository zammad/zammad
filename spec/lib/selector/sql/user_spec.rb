# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Selector::Sql, 'user' do
  describe 'user.role_ids' do
    let(:user_1)   { create(:agent) }
    let(:user_2)   { create(:admin) }
    let(:user_3)   { create(:customer) }
    let(:role_1)   { create(:role, name: 'Unused') }

    before do
      role_1
      user_1 && user_2 && user_3
    end

    it 'does find agents and admins', :aggregate_failures do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'user.id',
            operator: 'is',
            value:    [user_1.id.to_s, user_2.id.to_s, user_3.id.to_s],
          },
          {
            name:     'user.role_ids',
            operator: 'is',
            value:    Role.where(name: %w[Agent Admin]).pluck(:id).map(&:to_s),
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(2)
    end

    it 'does find non agents', :aggregate_failures do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'user.id',
            operator: 'is',
            value:    [user_1.id.to_s, user_2.id.to_s, user_3.id.to_s],
          },
          {
            name:     'user.role_ids',
            operator: 'is not',
            value:    Role.where(name: %w[Agent Admin]).pluck(:id).map(&:to_s),
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(1)
    end
  end

  describe 'ticket_customer.tickets_last_contact_at' do
    let(:user_1)   { create(:user) }
    let(:ticket_1) { create(:ticket, last_contact_at: Time.zone.now) }

    before do
      Ticket.destroy_all
      user_1
      ticket_1
    end

    it 'does find users by last contact', :aggregate_failures do
      condition = {
        operator:   'OR',
        conditions: [
          {
            name:     'ticket_customer.last_contact_at',
            operator: 'today',
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(1)
    end
  end

  describe 'ticket_customer.last_contact_agent_at' do
    let(:user_1) { create(:user) }
    let(:ticket_1) { create(:ticket, last_contact_agent_at: Time.zone.now) }

    before do
      Ticket.destroy_all
      user_1
      ticket_1
    end

    it 'does find users by last contact', :aggregate_failures do
      condition = {
        operator:   'OR',
        conditions: [
          {
            name:     'ticket_customer.last_contact_agent_at',
            operator: 'today',
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(1)
    end
  end

  describe 'ticket_customer.last_contact_customer_at' do
    let(:user_1) { create(:user) }
    let(:ticket_1) { create(:ticket, last_contact_customer_at: Time.zone.now) }

    before do
      Ticket.destroy_all
      user_1
      ticket_1
    end

    it 'does find users by last contact', :aggregate_failures do
      condition = {
        operator:   'OR',
        conditions: [
          {
            name:     'ticket_customer.last_contact_customer_at',
            operator: 'today',
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(1)
    end
  end

  describe 'ticket_customer.updated_at' do
    let(:user_1) { create(:user) }
    let(:ticket_1) { create(:ticket, updated_at: Time.zone.now) }

    before do
      Ticket.destroy_all
      user_1
      ticket_1
    end

    it 'does find users by last contact', :aggregate_failures do
      condition = {
        operator:   'OR',
        conditions: [
          {
            name:     'ticket_customer.updated_at',
            operator: 'today',
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(1)
    end
  end

  describe 'ticket_customer.existing' do
    let(:user_1) { create(:customer) }
    let(:user_2)   { create(:customer) }
    let(:user_3)   { create(:customer) }
    let(:ticket_1) { create(:ticket, customer: user_1) }

    before do
      user_1 && user_2 && user_3
      ticket_1
    end

    it 'does find users by customer tickets existing', :aggregate_failures do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'user.id',
            operator: 'is',
            value:    [user_1.id.to_s, user_2.id.to_s, user_3.id.to_s],
          },
          {
            name:     'ticket_customer.existing',
            operator: 'is',
            value:    'true',
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(1)
    end

    it 'does find users by without customer tickets existing', :aggregate_failures do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'user.id',
            operator: 'is',
            value:    [user_1.id.to_s, user_2.id.to_s, user_3.id.to_s],
          },
          {
            name:     'ticket_customer.existing',
            operator: 'is',
            value:    'false',
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(2)
    end

    it 'does not find user 1', :aggregate_failures do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'user.id',
            operator: 'is',
            value:    '1',
          },
          {
            name:     'ticket_customer.existing',
            operator: 'is',
            value:    'false',
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(0)
    end
  end

  describe 'ticket_customer.open_existing' do
    let(:user_1) { create(:customer) }
    let(:user_2)   { create(:customer) }
    let(:user_3)   { create(:customer) }
    let(:ticket_1) { create(:ticket, customer: user_1) }
    let(:ticket_2) { create(:ticket, customer: user_2, state: Ticket::State.find_by(name: 'closed')) }

    before do
      user_1 && user_2 && user_3
      ticket_1 && ticket_2
    end

    it 'does find users by customer tickets existing', :aggregate_failures do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'user.id',
            operator: 'is',
            value:    [user_1.id.to_s, user_2.id.to_s, user_3.id.to_s],
          },
          {
            name:     'ticket_customer.open_existing',
            operator: 'is',
            value:    'true',
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(1)
    end

    it 'does find users by without customer tickets existing', :aggregate_failures do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'user.id',
            operator: 'is',
            value:    [user_1.id.to_s, user_2.id.to_s, user_3.id.to_s],
          },
          {
            name:     'ticket_customer.open_existing',
            operator: 'is',
            value:    'false',
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(2)
    end
  end

  describe 'ticket_owner.existing' do
    let(:user_1) { create(:agent) }
    let(:user_2)   { create(:agent) }
    let(:user_3)   { create(:agent) }
    let(:ticket_1) { create(:ticket, owner: user_1) }

    before do
      user_1 && user_2 && user_3
      ticket_1
    end

    it 'does find users by owner tickets existing', :aggregate_failures do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'user.id',
            operator: 'is',
            value:    [user_1.id.to_s, user_2.id.to_s, user_3.id.to_s],
          },
          {
            name:     'ticket_owner.existing',
            operator: 'is',
            value:    'true',
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(1)
    end

    it 'does find users by without owner tickets existing', :aggregate_failures do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'user.id',
            operator: 'is',
            value:    [user_1.id.to_s, user_2.id.to_s, user_3.id.to_s],
          },
          {
            name:     'ticket_owner.existing',
            operator: 'is',
            value:    'false',
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(2)
    end
  end

  describe 'ticket_owner.open_existing' do
    let(:user_1) { create(:agent) }
    let(:user_2)   { create(:agent) }
    let(:user_3)   { create(:agent) }
    let(:ticket_1) { create(:ticket, owner: user_1) }
    let(:ticket_2) { create(:ticket, owner: user_2, state: Ticket::State.find_by(name: 'closed')) }

    before do
      user_1 && user_2 && user_3
      ticket_1 && ticket_2
    end

    it 'does find users by owner tickets existing', :aggregate_failures do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'user.id',
            operator: 'is',
            value:    [user_1.id.to_s, user_2.id.to_s, user_3.id.to_s],
          },
          {
            name:     'ticket_owner.open_existing',
            operator: 'is',
            value:    'true',
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(1)
    end

    it 'does find users by without owner tickets existing', :aggregate_failures do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'user.id',
            operator: 'is',
            value:    [user_1.id.to_s, user_2.id.to_s, user_3.id.to_s],
          },
          {
            name:     'ticket_owner.open_existing',
            operator: 'is',
            value:    'false',
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(2)
    end
  end
end
