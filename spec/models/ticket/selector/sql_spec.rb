# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Selector::Sql do
  context 'when relative time range is selected in ticket selector' do
    def get_condition(operator, range)
      {
        'ticket.created_at' => {
          operator: operator,
          range:    range, # minute|hour|day|month|
          value:    '10',
        },
      }
    end

    before do
      freeze_time
    end

    it 'calculates proper time interval, when operator is within last relative' do
      condition = get_condition('within last (relative)', 'minute')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([10.minutes.ago, Time.zone.now])
    end

    it 'calculates proper time interval, when operator is within next relative' do
      condition = get_condition('within next (relative)', 'hour')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([Time.zone.now, 10.hours.from_now])
    end

    it 'calculates proper time interval, when operator is before (relative)' do
      condition = get_condition('before (relative)', 'day')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([10.days.ago])
    end

    it 'calculates proper time interval, when operator is after (relative)' do
      condition = get_condition('after (relative)', 'week')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([10.weeks.from_now])
    end

    it 'calculates proper time interval, when operator is till (relative)' do
      condition = get_condition('till (relative)', 'month')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([10.months.from_now])
    end

    it 'calculates proper time interval, when operator is from (relative)' do
      condition = get_condition('from (relative)', 'year')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([10.years.ago])
    end

    context 'when today operator is used' do
      before do
        travel_to '2022-10-11 14:40:00'
        Setting.set('timezone_default', 'Europe/Berlin')
      end

      it 'calculates proper time interval when today operator is used', :aggregate_failures do
        _, bind_params = Ticket.selector2sql({ 'ticket.created_at' => { 'operator' => 'today' } })

        Time.use_zone(Setting.get('timezone_default_sanitized').presence) do
          expect(bind_params[0].to_s).to eq('2022-10-10 22:00:00 UTC')
          expect(bind_params[1].to_s).to eq('2022-10-11 21:59:59 UTC')
        end
      end
    end
  end

  describe 'Expert mode overview not working when using "owner is me" OR "subscribe is me #4547' do
    let(:agent)    { create(:agent, groups: [Group.first]) }
    let(:ticket_1) { create(:ticket, owner: agent, group: Group.first) }
    let(:ticket_2) { create(:ticket, group: Group.first) }
    let(:ticket_3) { create(:ticket, owner: agent, group: Group.first) }

    before do
      Ticket.destroy_all

      ticket_1 && ticket_2 && ticket_3
      create(:mention, mentionable: ticket_2, user: agent)
      create(:mention, mentionable: ticket_3, user: agent)
    end

    it 'does return 1 mentioned ticket' do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:          'ticket.mention_user_ids',
            operator:      'is',
            pre_condition: 'specific',
            value:         agent.id,
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(2)
    end

    it 'does return 1 owned ticket' do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:          'ticket.owner_id',
            operator:      'is',
            pre_condition: 'specific',
            value:         agent.id,
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(2)
    end

    it 'does return 1 owned & subscribed ticket' do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:          'ticket.mention_user_ids',
            operator:      'is',
            pre_condition: 'specific',
            value:         agent.id,
          },
          {
            name:          'ticket.owner_id',
            operator:      'is',
            pre_condition: 'specific',
            value:         agent.id,
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(1)
    end

    it 'does return 3 owned or subscribed tickets' do
      condition = {
        operator:   'OR',
        conditions: [
          {
            name:          'ticket.mention_user_ids',
            operator:      'is',
            pre_condition: 'specific',
            value:         agent.id,
          },
          {
            name:          'ticket.owner_id',
            operator:      'is',
            pre_condition: 'specific',
            value:         agent.id,
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(3)
    end
  end

  describe 'Overviews: "Organization" does not work as a pre-condition in the expert mode #4557' do
    let(:agent) { create(:agent, groups: [Group.first]) }
    let(:organization) { create(:organization) }
    let(:customer_1)   { create(:customer) }
    let(:customer_2)   { create(:customer, organization: organization) }
    let(:ticket_1)     { create(:ticket, customer: customer_1, group: Group.first) }
    let(:ticket_2)     { create(:ticket, customer: customer_2, group: Group.first) }

    before do
      Ticket.destroy_all
      ticket_1 && ticket_2
    end

    it 'does return 1 customer ticket without organization' do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:          'ticket.organization_id',
            operator:      'is',
            pre_condition: 'not_set',
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(1)
    end

    it 'does return 1 ticket with organization title' do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'organization.name',
            operator: 'is',
            value:    organization.name,
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(1)
    end

    it 'does return 1 ticket with organization and name' do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:          'ticket.organization_id',
            operator:      'is not',
            pre_condition: 'not_set',
          },
          {
            name:     'organization.name',
            operator: 'is',
            value:    organization.name,
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(1)
    end

    it 'does return 1 ticket without organization OR NO name' do
      condition = {
        operator:   'OR',
        conditions: [
          {
            name:          'ticket.organization_id',
            operator:      'is',
            pre_condition: 'not_set',
          },
          {
            name:     'organization.name',
            operator: 'is not',
            value:    organization.name,
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(1)
    end
  end

  describe '.condition_sql' do
    # We test this monstrous method indirectly though ".selectors" :(

    before do
      Ticket.destroy_all
      ticket
    end

    describe 'input fields' do

      let(:agent) { create(:agent, groups: [Group.first]) }
      let(:ticket) { create(:ticket, title: 'Some really nice title', owner: agent, group: Group.first) }
      let(:condition) do
        { operator: 'AND', conditions: [ {
          name:     'ticket.title',
          operator: operator,
          value:    value,
        } ] }
      end

      shared_examples 'finds the ticket' do
        it 'finds the ticket' do
          expect(Ticket.selectors(condition, { current_user: agent }).first).to eq 1
        end
      end

      shared_examples 'does not find the ticket' do
        it 'does not find the ticket' do
          expect(Ticket.selectors(condition, { current_user: agent }).first).to eq 0
        end
      end

      describe "operator 'contains'" do
        let(:operator) { 'contains' }

        context 'with matching string' do
          let(:value) { 'Some' }

          include_examples 'finds the ticket'
        end

        context 'with matching upcased string' do
          let(:value) { 'SOME' }

          include_examples 'finds the ticket'
        end

        context 'with non-matching string' do
          let(:value) { 'Other' }

          include_examples 'does not find the ticket'
        end
      end

      describe "operator 'contains not'" do
        let(:operator) { 'contains not' }

        context 'with matching string' do
          let(:value) { 'Some' }

          include_examples 'does not find the ticket'
        end

        context 'with matching upcased string' do
          let(:value) { 'SOME' }

          include_examples 'does not find the ticket'
        end

        context 'with non-matching string' do
          let(:value) { 'Other' }

          include_examples 'finds the ticket'
        end
      end

      describe "operator 'is'" do
        let(:operator) { 'is' }

        context 'with matching string' do
          let(:value) { 'Some really nice title' }

          include_examples 'finds the ticket'
        end

        # Skip for MySQL as it handles IN case insensitive.
        context 'with matching upcased string', db_adapter: :postgresql do
          let(:value) { 'SOME really nice title' }

          include_examples 'does not find the ticket'
        end

        context 'with non-matching string' do
          let(:value) { 'Another title' }

          include_examples 'does not find the ticket'
        end

        context 'with empty value' do
          let(:ticket) { create(:ticket, title: '', owner: agent, group: Group.first) }

          context 'with non-matching filter value' do
            let(:value) { 'Another title' }

            include_examples 'does not find the ticket'
          end

          context 'with empty filter value' do
            let(:value) { '' }

            include_examples 'finds the ticket'
          end
        end
      end

      describe "operator 'is any of'" do
        let(:operator) { 'is any of' }

        context 'with matching string' do
          let(:value) { ['Some really nice title', 'another example'] }

          include_examples 'finds the ticket'
        end

        # Skip for MySQL as it handles IN case insensitive.
        context 'with matching upcased string', db_adapter: :postgresql do
          let(:value) { ['SOME really nice title', 'another example'] }

          include_examples 'does not find the ticket'
        end

        context 'with non-matching string' do
          let(:value) { ['Another title', 'Example'] }

          include_examples 'does not find the ticket'
        end

        context 'with empty value' do
          let(:ticket) { create(:ticket, title: '', owner: agent, group: Group.first) }

          context 'with non-matching filter value' do
            let(:value) { ['Another title', 'Example'] }

            include_examples 'does not find the ticket'
          end

          context 'with empty filter value' do
            let(:value) { [] }

            include_examples 'finds the ticket'
          end
        end
      end

      describe "operator 'is not'" do
        let(:operator) { 'is not' }

        context 'with matching string' do
          let(:value) { 'Some really nice title' }

          include_examples 'does not find the ticket'
        end

        # Skip for MySQL as it handles IN case insensitive.
        context 'with matching upcased string', db_adapter: :postgresql do
          let(:value) { 'SOME really nice title' }

          include_examples 'finds the ticket'
        end

        context 'with non-matching string' do
          let(:value) { 'Another title' }

          include_examples 'finds the ticket'
        end

        context 'with empty value' do
          let(:ticket) { create(:ticket, title: '', owner: agent, group: Group.first) }

          context 'with non-matching filter value' do
            let(:value) { 'Another title' }

            include_examples 'finds the ticket'
          end

          context 'with empty filter value' do
            let(:value) { '' }

            include_examples 'does not find the ticket'
          end
        end
      end

      describe "operator 'is none of'" do
        let(:operator) { 'is none of' }

        context 'with matching string' do
          let(:value) { ['Some really nice title', 'another example'] }

          include_examples 'does not find the ticket'
        end

        # Skip for MySQL as it handles IN case insensitive.
        context 'with matching upcased string', db_adapter: :postgresql do
          let(:value) { %w[SO SOME] }

          include_examples 'finds the ticket'
        end

        context 'with non-matching string' do
          let(:value) { %w[A B] }

          include_examples 'finds the ticket'
        end

        context 'with empty value' do
          let(:ticket) { create(:ticket, title: '', owner: agent, group: Group.first) }

          context 'with non-matching filter value' do
            let(:value) { %w[A B] }

            include_examples 'finds the ticket'
          end

          context 'with empty filter value' do
            let(:value) { [] }

            include_examples 'does not find the ticket'
          end
        end
      end

      describe "operator 'starts with'" do
        let(:operator) { 'starts with' }

        context 'with matching string' do
          let(:value) { 'Some really' }

          include_examples 'finds the ticket'
        end

        context 'with matching upcased string' do
          let(:value) { 'SOME really' }

          include_examples 'finds the ticket'
        end

        context 'with non-matching string' do
          let(:value) { 'Another' }

          include_examples 'does not find the ticket'
        end
      end

      describe "operator 'starts with one of'" do
        let(:operator) { 'starts with one of' }

        context 'with matching string' do
          let(:value) { ['Some really', 'Some'] }

          include_examples 'finds the ticket'
        end

        context 'with matching upcased string' do
          let(:value) { ['SOME', 'Some really',] }

          include_examples 'finds the ticket'
        end

        context 'with non-matching string' do
          let(:value) { %w[Another Example] }

          include_examples 'does not find the ticket'
        end
      end

      describe "operator 'ends with'" do
        let(:operator) { 'ends with' }

        context 'with matching string' do
          let(:value) { 'nice title' }

          include_examples 'finds the ticket'
        end

        context 'with matching upcased string' do
          let(:value) { 'NICE title' }

          include_examples 'finds the ticket'
        end

        context 'with non-matching string' do
          let(:value) { 'Another title' }

          include_examples 'does not find the ticket'
        end
      end

      describe "operator 'ends with one of'" do
        let(:operator) { 'ends with one of' }

        context 'with matching string' do
          let(:value) { ['title', 'nice title'] }

          include_examples 'finds the ticket'
        end

        context 'with matching upcased string' do
          let(:value) { ['TITLE', 'NICE title'] }

          include_examples 'finds the ticket'
        end

        context 'with non-matching string' do
          let(:value) { ['Another title', 'Example'] }

          include_examples 'does not find the ticket'
        end
      end

      describe "operator 'matches regex'", mariadb: true do
        let(:operator) { 'matches regex' }

        context 'with matching string' do
          let(:value) { '^[a-s]' }

          include_examples 'finds the ticket'
        end

        context 'with matching upcased string' do
          let(:value) { '^[A-S]' }

          include_examples 'finds the ticket'
        end

        context 'with non-matching string' do
          let(:value) { '^[t-z]' }

          include_examples 'does not find the ticket'
        end
      end

      describe "operator 'does not match regex'", mariadb: true do
        let(:operator) { 'does not match regex' }

        context 'with matching string' do
          let(:value) { '^[a-s]' }

          include_examples 'does not find the ticket'
        end

        context 'with matching upcased string' do
          let(:value) { '^[A-S]' }

          include_examples 'does not find the ticket'
        end

        context 'with non-matching string' do
          let(:value) { '^[t-z]' }

          include_examples 'finds the ticket'
        end
      end

    end
  end

  describe '.valid?' do
    let(:instance) { described_class.new(selector: { operator: 'AND', conditions: [ condition ] }, options: {}) }

    context 'with valid conditions' do
      let(:condition) do
        {
          name:          'ticket.organization_id',
          operator:      'is',
          pre_condition: 'not_set',
        }
      end

      it 'validates' do
        expect(instance.valid?).to be true
      end
    end

    context 'with wrong ticket attribute' do
      let(:condition) do
        {
          name:          'ticket.unknown_field',
          operator:      'is',
          pre_condition: 'not_set',
        }
      end

      it 'does not validate' do
        expect(instance.valid?).to be false
      end
    end

    context 'with unknown operator' do
      let(:condition) do
        {
          name:     'ticket.title',
          operator: 'looks nice',
        }
      end

      it 'does not validate' do
        expect(instance.valid?).to be false
      end
    end

    context 'with invalid regular expression', mariadb: true do
      let(:condition) do
        {
          name:     'ticket.title',
          operator: 'matches regex',
          value:    '(',
        }
      end

      it 'does not validate' do
        expect(instance.valid?).to be false
      end
    end

  end
end
