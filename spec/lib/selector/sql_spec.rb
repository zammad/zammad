# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

      describe "operator 'matches'" do
        let(:operator) { 'matches' }

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

        context 'with wildcard matching' do
          let(:value) { 'som*' }

          include_examples 'finds the ticket'
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

        context 'with matching upcased string' do
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

        context 'with matching upcased string' do
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

        context 'with matching upcased string' do
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

        context 'with matching upcased string' do
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

      describe "operator 'matches regex'" do
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

      describe "operator 'does not match regex'" do
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

    describe 'integer fields', db_strategy: :reset do
      let(:attribute)                    { create(:object_manager_attribute_integer, object_name: 'Ticket') }
      let(:additional_ticket_attributes) { { attribute.name => 3 } }
      let(:name)                         { "ticket.#{attribute.name}" }

      before do
        attribute
        ObjectManager::Attribute.migration_execute
        ticket
      end

      describe "operator 'in range'" do
        let(:operator) { 'in range' }
        let(:value)    { %w[1 5] }

        include_examples 'finds the ticket'

        context 'when value is out of range' do
          let(:value) { %w[4 5] }

          include_examples 'does not find the ticket'
        end

        context 'when the edges are equal' do
          let(:value) { %w[3 3] }

          include_examples 'finds the ticket'
        end

        context 'when the upper edge is empty' do
          let(:value) { ['3', ''] }

          include_examples 'finds the ticket'
        end

        context 'when the lower edge is empty' do
          let(:value) { ['', '3'] }

          include_examples 'finds the ticket'
        end

        context 'when both values are empty' do
          let(:value) { ['', nil] }

          it 'raises an error' do
            expect { Ticket.selectors(condition, { current_user: agent }) }.to raise_error(RuntimeError)
          end
        end

        context 'when value is of wrong type' do
          let(:value) { '3' }

          it 'raises an error' do
            expect { Ticket.selectors(condition, { current_user: agent }) }.to raise_error(RuntimeError)
          end
        end
      end
    end

    describe 'accounted time' do
      let(:name)                         { 'ticket.time_unit' }
      let(:additional_ticket_attributes) { { 'time_unit' => 10.5 } }

      describe "operator 'in range'" do
        let(:operator) { 'in range' }
        let(:value)    { %w[10 11] }

        before do
          ticket
        end

        include_examples 'finds the ticket'

        context 'when value is out of range' do
          let(:value) { %w[10.75 11] }

          include_examples 'does not find the ticket'
        end

        context 'when value is negative' do
          let(:additional_ticket_attributes) { { 'time_unit' => '-0.5' } }
          let(:value)                        { ['-1', '0'] }

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

    describe 'external data source field', db_strategy: :reset do
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

    describe 'Invalid object selector conditions if value contains a question mark #6091', db_strategy: :reset do
      let(:attribute) do
        create(:object_manager_attribute_multi_tree_select,
               object_name:             'Ticket',
               additional_data_options: {
                 'options' => [
                   {
                     'name'     => 'trip?',
                     'value'    => 'trip?',
                     'children' => [
                       {
                         'name'  => 'done',
                         'value' => 'trip?::done',
                       }
                     ],
                   },
                 ],
               })
      end
      let(:name)  { "ticket.#{attribute.name}" }
      let(:value) { ['trip?::done'] }

      before do
        attribute
        ObjectManager::Attribute.migration_execute
        ticket
      end

      describe 'contains one' do
        let(:operator) { 'contains one' }

        context 'when valid check' do
          let(:additional_ticket_attributes) { { attribute.name => ['trip?::done', 'other'] } }

          it 'is valid' do
            expect(described_class.new(selector: condition, options: { current_user: User.find(1) }, target_class: Ticket).valid?).to be(true)
          end
        end

        context 'when ticket value matches' do
          let(:additional_ticket_attributes) { { attribute.name => ['trip?::done', 'other'] } }

          include_examples 'finds the ticket'
        end

        context 'when ticket value does not match' do
          let(:additional_ticket_attributes) { { attribute.name => ['other'] } }

          include_examples 'does not find the ticket'
        end
      end

      describe 'contains all' do
        let(:operator) { 'contains all' }

        context 'when valid check' do
          let(:additional_ticket_attributes) { { attribute.name => ['trip?::done', 'other'] } }

          it 'is valid' do
            expect(described_class.new(selector: condition, options: { current_user: User.find(1) }, target_class: Ticket).valid?).to be(true)
          end
        end

        context 'when ticket value matches' do
          let(:additional_ticket_attributes) { { attribute.name => ['trip?::done'] } }

          include_examples 'finds the ticket'
        end

        context 'when ticket value does not match' do
          let(:additional_ticket_attributes) { { attribute.name => ['other'] } }

          include_examples 'does not find the ticket'
        end
      end
    end
  end

  describe '.valid?' do
    let(:block_operator) { 'AND' }
    let(:instance) { described_class.new(selector: { operator: block_operator, conditions: [ condition ] }, options: {}) }

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

    context 'with invalid regular expression' do
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

    context 'with external data source field', db_strategy: :reset do
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

    context 'with invalid block conditions' do
      let(:block_operator) { ';;;' }
      let(:condition) do
        {
          name:          'ticket.organization_id',
          operator:      'is',
          pre_condition: 'not_set',
        }
      end

      it 'does not validate' do
        expect(instance.valid?).to be false
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

  describe 'ticket selector' do
    let(:group) do
      Group.create_or_update(
        name:          'SelectorTest',
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:agent1) do
      User.create_or_update(
        login:         'ticket-selector-agent1@example.com',
        firstname:     'Notification',
        lastname:      'Agent1',
        email:         'ticket-selector-agent1@example.com',
        password:      'agentpw',
        active:        true,
        roles:         Role.where(name: 'Agent'),
        groups:        [group],
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:agent2) do
      User.create_or_update(
        login:         'ticket-selector-agent2@example.com',
        firstname:     'Notification',
        lastname:      'Agent2',
        email:         'ticket-selector-agent2@example.com',
        password:      'agentpw',
        active:        true,
        roles:         Role.where(name: 'Agent'),
        updated_at:    '2015-02-05 16:38:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:organization1) do
      Organization.create_if_not_exists(
        name:          'Selector Org',
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:customer1) do
      User.create_or_update(
        login:           'ticket-selector-customer1@example.com',
        firstname:       'Notification',
        lastname:        'Customer1',
        email:           'ticket-selector-customer1@example.com',
        password:        'customerpw',
        active:          true,
        organization_id: organization1.id,
        roles:           Role.where(name: 'Customer'),
        updated_at:      '2015-02-05 16:37:00',
        updated_by_id:   1,
        created_by_id:   1,
      )
    end
    let(:customer2) do
      User.create_or_update(
        login:           'ticket-selector-customer2@example.com',
        firstname:       'Notification',
        lastname:        'Customer2',
        email:           'ticket-selector-customer2@example.com',
        password:        'customerpw',
        active:          true,
        organization_id: nil,
        roles:           Role.where(name: 'Customer'),
        updated_at:      '2015-02-05 16:37:00',
        updated_by_id:   1,
        created_by_id:   1,
      )
    end

    before do
      agent1 && agent2 && customer1 && customer2
      Ticket.where(group_id: group.id).destroy_all
    end

    describe 'ticket create' do
      it 'matches created tickets depending on condition and current user', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        Ticket.destroy_all

        ticket1 = Ticket.create!(
          title:         'some title1',
          group:         group,
          customer_id:   customer1.id,
          owner_id:      agent1.id,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          created_at:    '2015-02-05 16:37:00',
          # updated_at: '2015-02-05 17:37:00',
          updated_by_id: 1,
          created_by_id: 1,
        )
        expect(ticket1).to be_a(Ticket)
        expect(ticket1.customer.id).to eq(customer1.id)
        expect(ticket1.organization.id).to eq(organization1.id)
        travel 1.second

        ticket2 = Ticket.create!(
          title:         'some title2',
          group:         group,
          customer_id:   customer2.id,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          created_at:    '2015-02-05 16:37:00',
          # updated_at: '2015-02-05 17:37:00',
          updated_by_id: 1,
          created_by_id: 1,
        )
        expect(ticket2).to be_a(Ticket)
        expect(ticket2.customer.id).to eq(customer2.id)
        expect(ticket2.organization_id).to be_nil
        travel 1.second

        ticket3 = Ticket.create!(
          title:         'some title3',
          group:         group,
          customer_id:   customer2.id,
          state:         Ticket::State.lookup(name: 'open'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          created_at:    '2015-02-05 16:37:00',
          # updated_at: '2015-02-05 17:37:00',
          updated_by_id: 1,
          created_by_id: 1,
        )
        ticket3.update_columns(escalation_at: '2015-02-06 10:00:00')
        expect(ticket3).to be_a(Ticket)
        expect(ticket3.customer.id).to eq(customer2.id)
        expect(ticket3.organization_id).to be_nil
        travel 1.second

        # search not matching
        condition = {
          'ticket.state_id' => {
            operator: 'is',
            value:    [99],
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(0)

        # search matching with empty value / missing key
        condition = {
          'ticket.group_id' => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.state_id' => {
            operator: 'is',
          },
        }

        ticket_count, = Ticket.selectors(condition, limit: 10)
        expect(ticket_count).to be_nil

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to be_nil

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to be_nil

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to be_nil

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to be_nil

        # search matching with empty value []
        condition = {
          'ticket.group_id' => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.state_id' => {
            operator: 'is',
            value:    [],
          },
        }

        ticket_count, = Ticket.selectors(condition, limit: 10)
        expect(ticket_count).to be_nil

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to be_nil

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to be_nil

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to be_nil

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to be_nil

        # search matching with empty value ''
        condition = {
          'ticket.group_id' => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.state_id' => {
            operator: 'is',
          },
        }

        ticket_count, = Ticket.selectors(condition, limit: 10)
        expect(ticket_count).to be_nil

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to be_nil

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to be_nil

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to be_nil

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to be_nil

        # search matching
        condition = {
          'ticket.group_id' => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.state_id' => {
            operator: 'is',
            value:    [Ticket::State.lookup(name: 'new').id],
          },
        }

        ticket_count, = Ticket.selectors(condition, limit: 10)
        expect(ticket_count).to eq(2)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(2)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(1)

        condition = {
          'ticket.group_id' => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.state_id' => {
            operator: 'is not',
            value:    [Ticket::State.lookup(name: 'open').id],
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10)
        expect(ticket_count).to eq(2)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(2)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(1)

        condition = {
          'ticket.escalation_at' => {
            operator: 'is not',
            value:    nil,
          }
        }
        ticket_count, = Ticket.selectors(condition, limit: 10)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(1)

        # search - created_at
        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.created_at' => {
            operator: 'after (absolute)', # before (absolute)
            value:    '2015-02-05T16:00:00.000Z',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(3)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(2)

        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.created_at' => {
            operator: 'after (absolute)', # before (absolute)
            value:    '2015-02-05T18:00:00.000Z',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(0)

        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.created_at' => {
            operator: 'before (absolute)',
            value:    '2015-02-05T18:00:00.000Z',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(3)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(2)

        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.created_at' => {
            operator: 'before (absolute)',
            value:    '2015-02-05T16:00:00.000Z',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(0)

        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.created_at' => {
            operator: 'before (relative)',
            range:    'day', # minute|hour|day|month|
            value:    '10',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(3)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(2)

        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.created_at' => {
            operator: 'till (relative)',
            range:    'year', # minute|hour|day|month|
            value:    '10',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(3)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(2)

        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.created_at' => {
            operator: 'within last (relative)',
            range:    'year', # minute|hour|day|month|
            value:    '20',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(3)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(2)

        # search - updated_at
        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.updated_at' => {
            operator: 'before (absolute)',
            value:    1.day.from_now.iso8601,
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(3)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(2)

        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.updated_at' => {
            operator: 'before (absolute)',
            value:    1.day.ago.iso8601,
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(0)

        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.updated_at' => {
            operator: 'after (absolute)',
            value:    1.day.from_now.iso8601,
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(0)

        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.updated_at' => {
            operator: 'after (absolute)',
            value:    1.day.ago.iso8601,
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(3)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(2)

        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.updated_at' => {
            operator: 'before (relative)',
            range:    'day', # minute|hour|day|month|
            value:    '10',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(0)

        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.updated_at' => {
            operator: 'till (relative)',
            range:    'year', # minute|hour|day|month|
            value:    '10',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(3)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(2)

        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.updated_at' => {
            operator: 'within last (relative)',
            range:    'year', # minute|hour|day|month|
            value:    '10',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(3)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(2)

        # invalid conditions
        expect { Ticket.selectors(nil, limit: 10) }.to raise_error(RuntimeError)

        # search with customers
        condition = {
          'ticket.group_id' => {
            operator: 'is',
            value:    group.id,
          },
          'customer.email'  => {
            operator: 'contains',
            value:    'ticket-selector-customer1',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(0)

        condition = {
          'ticket.group_id' => {
            operator: 'is',
            value:    group.id,
          },
          'customer.email'  => {
            operator: 'contains not',
            value:    'ticket-selector-customer1-not_existing',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(3)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(2)

        # search with organizations
        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'organization.name' => {
            operator: 'contains',
            value:    'selector',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(0)

        # search with organizations
        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'organization.name' => {
            operator: 'contains',
            value:    'selector',
          },
          'customer.email'    => {
            operator: 'contains',
            value:    'ticket-selector-customer1',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(0)

        condition = {
          'ticket.group_id'   => {
            operator: 'is',
            value:    group.id,
          },
          'organization.name' => {
            operator: 'contains',
            value:    'selector',
          },
          'customer.email'    => {
            operator: 'contains not',
            value:    'ticket-selector-customer1',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(0)

        # with owner/customer/org
        condition = {
          'ticket.group_id' => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.owner_id' => {
            operator:      'is',
            pre_condition: 'specific',
            value:         agent1.id,
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(0)

        condition = {
          'ticket.group_id' => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.owner_id' => {
            operator:      'is',
            pre_condition: 'specific',
            # value: agent1.id, # value is not set, no result should be shown
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to be_nil

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to be_nil

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to be_nil

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to be_nil

        condition = {
          'ticket.group_id' => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.owner_id' => {
            operator:      'is',
            pre_condition: 'not_set',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(2)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(2)

        condition = {
          'ticket.group_id' => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.owner_id' => {
            operator:      'is not',
            pre_condition: 'not_set',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(0)

        UserInfo.current_user_id = agent1.id
        condition = {
          'ticket.group_id' => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.owner_id' => {
            operator:      'is',
            pre_condition: 'current_user.id',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(0)

        UserInfo.current_user_id = agent2.id
        condition = {
          'ticket.group_id' => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.owner_id' => {
            operator:      'is',
            pre_condition: 'current_user.id',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(0)

        UserInfo.current_user_id = customer1.id
        condition = {
          'ticket.group_id'    => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.customer_id' => {
            operator:      'is',
            pre_condition: 'current_user.id',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(2)

        UserInfo.current_user_id = customer2.id
        condition = {
          'ticket.group_id'    => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.customer_id' => {
            operator:      'is',
            pre_condition: 'current_user.id',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(2)

        ticket_count, = Ticket.selectors(condition, limit: 10)
        expect(ticket_count).to eq(2)

        UserInfo.current_user_id = customer1.id
        condition = {
          'ticket.group_id'        => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.organization_id' => {
            operator:      'is',
            pre_condition: 'current_user.organization_id',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(0)

        UserInfo.current_user_id = customer2.id
        condition = {
          'ticket.group_id'        => {
            operator: 'is',
            value:    group.id,
          },
          'ticket.organization_id' => {
            operator:      'is',
            pre_condition: 'current_user.organization_id',
          },
        }
        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer1)
        expect(ticket_count).to eq(1)

        ticket_count, = Ticket.selectors(condition, limit: 10, current_user: customer2)
        expect(ticket_count).to eq(0)

        ticket_count, = Ticket.selectors(condition, limit: 10)
        expect(ticket_count).to eq(0)
        travel_back
      end
    end

    describe 'ticket tags filter' do
      it 'filters tickets by tags with contains all/one operators', :aggregate_failures do
        ticket_tags_1 = Ticket.create!(
          title:         'some title1',
          group:         group,
          customer_id:   customer1.id,
          owner_id:      agent1.id,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          created_at:    '2015-02-05 16:37:00',
          updated_by_id: 1,
          created_by_id: 1,
        )
        ticket_tags_2 = Ticket.create!(
          title:         'some title1',
          group:         group,
          customer_id:   customer1.id,
          owner_id:      agent1.id,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          created_at:    '2015-02-05 16:37:00',
          updated_by_id: 1,
          created_by_id: 1,
        )
        Ticket.create!(
          title:         'some title1',
          group:         group,
          customer_id:   customer1.id,
          owner_id:      agent1.id,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          created_at:    '2015-02-05 16:37:00',
          updated_by_id: 1,
          created_by_id: 1,
        )

        Tag.tag_add(
          object:        'Ticket',
          o_id:          ticket_tags_1.id,
          item:          'contains_all_1',
          created_by_id: 1,
        )
        Tag.tag_add(
          object:        'Ticket',
          o_id:          ticket_tags_1.id,
          item:          'contains_all_2',
          created_by_id: 1,
        )
        Tag.tag_add(
          object:        'Ticket',
          o_id:          ticket_tags_1.id,
          item:          'contains_all_3',
          created_by_id: 1,
        )
        Tag.tag_add(
          object:        'Ticket',
          o_id:          ticket_tags_2.id,
          item:          'contains_all_3',
          created_by_id: 1,
        )

        # search all with contains all
        condition = {
          'ticket.tags' => {
            operator: 'contains all',
            value:    'contains_all_1, contains_all_2, contains_all_3',
          },
        }
        ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)

        condition = {
          'ticket.tags' => {
            operator: 'contains all',
            value:    'contains_all_1, contains_all_2, contains_all_3, xxx',
          },
        }
        ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(0)

        # search all with contains one
        condition = {
          'ticket.tags' => {
            operator: 'contains one',
            value:    'contains_all_1, contains_all_2, contains_all_3',
          },
        }
        ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(2)

        condition = {
          'ticket.tags' => {
            operator: 'contains one',
            value:    'contains_all_1, contains_all_2'
          },
        }
        ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)

        # search all with contains one not
        condition = {
          'ticket.tags' => {
            operator: 'contains one',
            value:    'contains_all_1, contains_all_3'
          },
        }
        ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(2)

        condition = {
          'ticket.tags' => {
            operator: 'contains one',
            value:    'contains_all_1, contains_all_2, contains_all_3'
          },
        }
        ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(2)
      end
    end

    describe 'ticket title with certain content' do
      it 'matches ticket titles with special characters using contains and is operators', :aggregate_failures do
        Ticket.create!(
          title:         'some_title1',
          group:         group,
          customer_id:   customer1.id,
          owner_id:      agent1.id,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          created_at:    '2015-02-05 16:37:00',
          updated_by_id: 1,
          created_by_id: 1,
        )
        Ticket.create!(
          title:         'some::title2',
          group:         group,
          customer_id:   customer1.id,
          owner_id:      agent1.id,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          created_at:    '2015-02-05 16:37:00',
          updated_by_id: 1,
          created_by_id: 1,
        )
        Ticket.create!(
          title:         'some-title3',
          group:         group,
          customer_id:   customer1.id,
          owner_id:      agent1.id,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          created_at:    '2015-02-05 16:37:00',
          updated_by_id: 1,
          created_by_id: 1,
        )

        # search all with contains
        condition = {
          'ticket.title' => {
            operator: 'contains',
            value:    'some_title1',
          },
        }
        ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)

        condition = {
          'ticket.title' => {
            operator: 'contains',
            value:    'some::title2',
          },
        }
        ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)

        condition = {
          'ticket.title' => {
            operator: 'contains',
            value:    'some-title3',
          },
        }
        ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)

        # search all with is
        condition = {
          'ticket.title' => {
            operator: 'is',
            value:    'some_title1',
          },
        }
        ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)

        condition = {
          'ticket.title' => {
            operator: 'is',
            value:    'some::title2',
          },
        }
        ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)

        condition = {
          'ticket.title' => {
            operator: 'is',
            value:    'some-title3',
          },
        }
        ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(1)
      end
    end

    describe 'access: "ignore"' do
      it 'bypasses the ticket permission checks when access is set to ignore', :aggregate_failures do
        Ticket.destroy_all

        Ticket.create!(
          title:         'some title1',
          group:         group,
          customer_id:   customer1.id,
          owner_id:      agent1.id,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          created_at:    '2015-02-05 16:37:00',
          updated_by_id: 1,
          created_by_id: 1,
        )

        Ticket.create!(
          title:         'some title2',
          group:         group,
          customer_id:   customer1.id,
          owner_id:      agent1.id,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          created_at:    '2015-02-05 16:37:00',
          updated_by_id: agent2.id,
          created_by_id: 1,
        )

        condition = {
          'ticket.title' => {
            operator: 'contains',
            value:    'some',
          },
        }

        # visible by owner
        ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: agent1)
        expect(ticket_count).to eq(2)

        # not visible by another agent
        ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        # visible by another user when access: "ignore". For example, when tickets are performed after action of another user
        ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: agent2, access: 'ignore')
        expect(ticket_count).to eq(2)

        condition2 = {
          'ticket.updated_by_id' => {
            operator:         'is',
            pre_condition:    'current_user.id',
            value:            '',
            value_completion: ''
          }
        }

        # not visible by another agent even if matches current user precondition
        ticket_count, _tickets = Ticket.selectors(condition2, limit: 10, current_user: agent2)
        expect(ticket_count).to eq(0)

        # visible by another user when access: "ignore" if matches current user precondition
        ticket_count, _tickets = Ticket.selectors(condition2, limit: 10, current_user: agent2, access: 'ignore')
        expect(ticket_count).to eq(1)
      end
    end
  end
end
