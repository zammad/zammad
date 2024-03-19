# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Selector::Sql do
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

        Time.use_zone(Setting.get('timezone_default')) do
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

    before do
      Ticket.destroy_all
    end

    let(:agent) { create(:agent, groups: [Group.first]) }
    let(:ticket_attributes) do
      {
        title: 'Some really nice title',
        owner: agent,
        group: Group.first
      }
    end
    let(:additional_ticket_attributes) { {} }
    let(:ticket)                       { create(:ticket, ticket_attributes.merge(additional_ticket_attributes)) }
    let(:condition) do
      { operator: 'AND', conditions: [ {
        name:     name,
        operator: operator,
        value:    value,
      } ] }
    end

    describe 'input fields' do
      let(:name) { 'ticket.title' }

      before do
        ticket
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

        context 'with empty-looking values in DB' do
          let(:value) { 'Some' }
          let(:name)  { 'ticket.note' }

          before { ticket.update! note: database_value }

          context 'when value is empty string' do
            let(:database_value) { '' }

            include_examples 'finds the ticket'
          end

          context 'when value is NULL' do
            let(:database_value) { nil }

            include_examples 'finds the ticket'
          end
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
          let(:ticket_attributes) do
            {
              title: '',
              owner: agent,
              group: Group.first
            }
          end

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
          let(:ticket_attributes) do
            {
              title: '',
              owner: agent,
              group: Group.first
            }
          end

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
          let(:ticket_attributes) do
            {
              title: '',
              owner: agent,
              group: Group.first
            }
          end

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
          let(:ticket_attributes) do
            {
              title: '',
              owner: agent,
              group: Group.first
            }
          end

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

        context 'with special characters' do
          let(:ticket_attributes) do
            {
              title: '\\ [ ]',
              owner: agent,
              group: Group.first
            }
          end
          let(:value) { '\\ [ ]' }

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

        context 'with special characters' do
          let(:ticket_attributes) do
            {
              title: '[ ] \\',
              owner: agent,
              group: Group.first
            }
          end
          let(:value) { '[ ] \\' }

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

    describe 'complex conditions' do
      context "when 'contains not' operator is after negative operator" do
        let(:condition) do
          { operator: 'AND', conditions: [
            {
              name:     'ticket.title',
              operator: 'is not',
              value:    'title',
            }, {
              name:     'ticket.note',
              operator: 'contains not',
              value:    'some',
            },
          ] }
        end

        let(:additional_ticket_attributes) { { title: 'title' } }

        before do
          ticket
        end

        include_examples 'does not find the ticket'
      end

      context "when 'contains not' operator is before negative operator" do
        let(:condition) do
          { operator: 'AND', conditions: [
            {
              name:     'ticket.note',
              operator: 'contains not',
              value:    'some',
            }, {
              name:     'ticket.title',
              operator: 'is not',
              value:    'title',
            }
          ] }
        end

        let(:additional_ticket_attributes) { { title: 'title' } }

        before do
          ticket
        end

        include_examples 'does not find the ticket'
      end

      context "when 'contains not' operator on a related table is after negative operator" do
        let(:condition) do
          { operator: 'AND', conditions: [
            {
              name:     'ticket.title',
              operator: 'is not',
              value:    'title',
            }, {
              name:     'customer.email',
              operator: 'contains not',
              value:    'some',
            },
          ] }
        end

        let(:additional_ticket_attributes) { { title: 'title' } }

        before do
          ticket
        end

        include_examples 'does not find the ticket'
      end

      context "when 'contains not' operator on a related table is before negative operator" do
        let(:condition) do
          { operator: 'AND', conditions: [
            {
              name:     'customer.email',
              operator: 'contains not',
              value:    'some',
            }, {
              name:     'ticket.title',
              operator: 'is not',
              value:    'title',
            }
          ] }
        end

        let(:additional_ticket_attributes) { { title: 'title' } }

        before do
          ticket
        end

        include_examples 'does not find the ticket'
      end
    end

    describe 'external data source field', db_adapter: :postgresql, db_strategy: :reset do
      let(:external_data_source_attribute) do
        create(:object_manager_attribute_autocompletion_ajax_external_data_source,
               name: 'external_data_source_attribute')
      end

      let(:name) { "ticket.#{external_data_source_attribute.name}" }

      let(:external_data_source_attribute_value) { 123 }
      let(:additional_ticket_attributes) do
        {
          external_data_source_attribute.name => {
            value: external_data_source_attribute_value,
            label: 'Example'
          }
        }
      end

      before do
        external_data_source_attribute
        ObjectManager::Attribute.migration_execute

        ticket
      end

      describe "operator 'is'" do
        let(:operator) { 'is' }

        context 'with matching integer as value' do
          let(:value) do
            {
              value: 123,
              label: 'Example'
            }
          end

          include_examples 'finds the ticket'
        end

        context 'with multiple values for matching' do
          let(:value) do
            [
              {
                value: 123,
                label: 'Example'
              },
              {
                value: '987',
                label: 'Example'
              }
            ]
          end

          include_examples 'finds the ticket'
        end

        context 'with string' do
          context 'with matching string as value' do
            let(:external_data_source_attribute_value) { 'Example' }
            let(:value) do
              {
                value: 'Example',
                label: 'Example'
              }
            end

            include_examples 'finds the ticket'
          end

          context 'with non-matching string' do
            let(:value) do
              {
                value: 'Wrong',
                label: 'Wrong'
              }
            end

            include_examples 'does not find the ticket'
          end
        end

        context 'with matching boolean as value' do
          let(:external_data_source_attribute_value) { true }
          let(:value) do
            {
              value: true,
              label: 'Yes'
            }
          end

          include_examples 'finds the ticket'
        end
      end

      describe "operator 'is not'" do
        let(:operator) { 'is not' }

        context 'with matching integer as value' do
          let(:value) do
            {
              value: 986,
              label: 'Example'
            }
          end

          include_examples 'finds the ticket'
        end

        context 'with matching integer' do
          let(:value) do
            {
              value: 123,
              label: 'Example'
            }
          end

          include_examples 'does not find the ticket'
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

    context 'with external data source field', db_adapter: :postgresql, db_strategy: :reset do
      let(:external_data_source_attribute) do
        create(:object_manager_attribute_autocompletion_ajax_external_data_source,
               name: 'external_data_source_attribute')
      end

      let(:condition) do
        {
          name:     "ticket.#{external_data_source_attribute.name}",
          operator: 'is',
          value:    {
            value: 123,
            label: 'Example'
          }
        }
      end

      before do
        external_data_source_attribute
        ObjectManager::Attribute.migration_execute
      end

      it 'validates' do
        expect(instance.valid?).to be true
      end
    end
  end

  describe 'Error 500 if overview with "out of office replacement" filter is set to "specific user" #4599' do
    let(:agent)                 { create(:agent) }
    let(:agent_ooo)             { create(:agent, :ooo, ooo_agent: agent_ooo_replacement) }
    let(:agent_ooo_replacement) { create(:agent) }
    let(:condition) do
      {
        'ticket.out_of_office_replacement_id': {
          operator:         'is',
          pre_condition:    'specific',
          value:            [
            agent_ooo_replacement.id.to_s,
          ],
          value_completion: ''
        }
      }
    end

    before do
      agent_ooo
    end

    it 'calculates the out of office user ids for the out of office replacement agent' do
      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params.flatten).to include(agent_ooo.id)
    end
  end

  describe 'Performance: Improve tags performance when only one tag is used' do
    it 'does optimize the sql when one element is set' do
      sql, = Ticket.selector2sql({
                                   'ticket.tags' => {
                                     operator: 'contains all',
                                     value:    'blub',
                                   },
                                 })

      expect(sql).not_to include('SELECT')
    end

    it 'does not optimize the sql when multiple elements are set' do
      sql, = Ticket.selector2sql({
                                   'ticket.tags' => {
                                     operator: 'contains all',
                                     value:    't1,t2',
                                   },
                                 })

      expect(sql).to include('SELECT')
    end
  end
end
