# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormUpdater::Updater::Search::AdvancedFilters) do
  subject(:updater) do
    described_class.new(
      context:         context,
      relation_fields: [],
      meta:            meta,
      data:            data,
      id:              nil,
    )
  end

  let(:group)                      { create(:group) }
  let(:user)                       { create(:agent, groups: [group]) }
  let(:context)                    { { current_user: user } }
  let(:entity)                     { 'Ticket' }
  let(:filter_relation_fields)     { [] }
  let(:filter_autocomplete_fields) { [] }
  let(:meta) do
    {
      initial:         true,
      additional_data: {
        'entity'                   => entity,
        'filterRelationFields'     => filter_relation_fields,
        'filterAutocompleteFields' => filter_autocomplete_fields,
      },
    }
  end
  let(:data) { {} }

  def filter_options(name)
    updater.resolve.dig(:fields, 'filters', :filterAttributeOptions, name)
  end

  describe '#authorized?' do
    it 'is authorized for an agent on Ticket entity' do
      expect(updater.authorized?).to be true
    end

    context 'with customer + Ticket entity' do
      let(:user) { create(:customer) }

      it 'is not authorized — advanced filters are agent-only (FE Ticket plugin gates customers out via filterPermissions)' do
        expect(updater.authorized?).to be false
      end
    end

    context 'with admin.user-only user + User entity' do
      let(:entity) { 'User' }
      let(:user)   { create(:user, roles: [create(:role, permissions: [Permission.find_by(name: 'admin.user')])]) }

      it { expect(updater.authorized?).to be true }
    end

    context 'with customer + User entity' do
      let(:entity) { 'User' }
      let(:user)   { create(:customer) }

      it 'is not authorized (customer cannot search users)' do
        expect(updater.authorized?).to be false
      end
    end

    context 'with unknown entity' do
      let(:entity) { 'Foo' }

      it { expect(updater.authorized?).to be false }
    end

    context 'with missing entity' do
      let(:meta) { { initial: true, additional_data: {} } }

      it { expect(updater.authorized?).to be false }
    end

    context 'with a user that has no search-eligible permission' do
      let(:user) { create(:user, roles: [create(:role, permissions: [Permission.find_by(name: 'admin.api')])]) }

      it { expect(updater.authorized?).to be false }
    end
  end

  describe '#resolve' do
    context 'with no filter relation fields' do
      it 'returns an empty fields hash' do
        expect(updater.resolve[:fields]).to eq({})
      end
    end

    context 'with a Group relation' do
      let(:filter_relation_fields) { [{ 'name' => 'ticket.group_id', 'relation' => 'Group' }] }
      let!(:other_group)           { create(:group) }

      it 'returns the agent-accessible groups as options' do
        expect(filter_options('ticket.group_id')).to include(hash_including(value: group.id))
      end

      it 'omits groups the agent has no access to' do
        expect(filter_options('ticket.group_id').pluck(:value)).not_to include(other_group.id)
      end

      it 'returns the tree shape from Relation::Group when a parent is present' do
        child = create(:group, parent: group)
        user.groups << child

        options = filter_options('ticket.group_id')
        root = options.find { |o| o[:value] == group.id }
        expect(root[:children]).to include(hash_including(value: child.id))
      end
    end

    context 'with a TicketState relation' do
      let(:filter_relation_fields) { [{ 'name' => 'ticket.state_id', 'relation' => 'TicketState' }] }

      it 'returns active states as options' do
        expect(filter_options('ticket.state_id')).to all(include(:value, :label))
      end
    end

    context 'with a foreign-entity filter relation on a Ticket form' do
      let(:entity) { 'Ticket' }
      let(:filter_relation_fields) do
        [
          { 'name' => 'user.group_ids',  'relation' => 'Group' },
          { 'name' => 'ticket.state_id', 'relation' => 'TicketState' },
        ]
      end

      it 'drops the foreign entry but keeps the matching one' do
        keys = updater.resolve.dig(:fields, 'filters', :filterAttributeOptions)&.keys
        expect(keys).to contain_exactly('ticket.state_id')
      end
    end

    context 'with a foreign-entity filter relation on a User form' do
      let(:entity) { 'User' }
      let(:user)   { create(:agent, groups: [group]) }
      let(:filter_relation_fields) do
        [{ 'name' => 'ticket.state_id', 'relation' => 'TicketState' }]
      end

      it 'drops the ticket-prefixed entry on a User-entity form' do
        expect(updater.resolve[:fields]).to eq({})
      end
    end

    context 'with an unknown relation type' do
      let(:filter_relation_fields) { [{ 'name' => 'ticket.unknown', 'relation' => 'NoSuchRelation' }] }

      it 'raises so the misconfiguration surfaces (silent skip would leave the filter row without options)' do
        expect { updater.resolve }.to raise_error(%r{Cannot resolve relation type})
      end
    end

    context 'with a customer asking for ticket.group_id options' do
      let(:user)                   { create(:customer) }
      let(:filter_relation_fields) { [{ 'name' => 'ticket.group_id', 'relation' => 'Group' }] }

      before { create(:group) }

      it 'returns an empty list (non-agent handling deferred)' do
        expect(filter_options('ticket.group_id')).to eq([])
      end
    end

    describe 'autocomplete filter prefill' do
      let(:customer)     { create(:customer) }
      let(:other_agent)  { create(:agent, groups: [group]) }
      let(:organization) { create(:organization) }

      def filter_row(name, value)
        { 'name' => name, 'operator' => 'is', 'value' => value }
      end

      context 'with an agent-type filter row (owner_id)' do
        let(:filter_autocomplete_fields) do
          [{ 'name' => 'ticket.owner_id', 'autocompleteFilterType' => 'agent' }]
        end
        let(:data) { { 'filters' => [filter_row('ticket.owner_id', [other_agent.id])] } }

        it 'resolves the User into a canonical option entry' do
          options = filter_options('ticket.owner_id')
          expect(options).to contain_exactly(
            hash_including(value: other_agent.id, label: other_agent.fullname.presence || other_agent.login)
          )
        end

        it 'includes the serialized GraphQL object in the option' do
          option = filter_options('ticket.owner_id').first
          expect(option[:object]).to include('__typename' => 'User', 'firstname' => other_agent.firstname)
        end
      end

      context 'with a customer-type filter row (customer_id)' do
        let(:filter_autocomplete_fields) do
          [{ 'name' => 'ticket.customer_id', 'autocompleteFilterType' => 'customer' }]
        end
        let(:data) { { 'filters' => [filter_row('ticket.customer_id', [customer.id])] } }

        it 'reuses the same User handler and emits the option' do
          expect(filter_options('ticket.customer_id')).to contain_exactly(
            hash_including(value: customer.id)
          )
        end
      end

      context 'with an organization-type filter row' do
        let(:filter_autocomplete_fields) do
          [{ 'name' => 'ticket.organization_id', 'autocompleteFilterType' => 'organization' }]
        end
        let(:data) { { 'filters' => [filter_row('ticket.organization_id', [organization.id])] } }

        it 'resolves the Organization into a canonical option entry' do
          expect(filter_options('ticket.organization_id')).to contain_exactly(
            hash_including(value: organization.id, label: organization.name)
          )
        end
      end

      context 'with multiple IDs in a single row' do
        let(:another_agent) { create(:agent, groups: [group]) }
        let(:filter_autocomplete_fields) do
          [{ 'name' => 'ticket.owner_id', 'autocompleteFilterType' => 'agent' }]
        end
        let(:data) do
          { 'filters' => [filter_row('ticket.owner_id', [other_agent.id, another_agent.id])] }
        end

        it 'returns one option per id, preserving order' do
          expect(filter_options('ticket.owner_id').pluck(:value)).to eq([other_agent.id, another_agent.id])
        end
      end

      context 'with a scalar (single-value) filter row' do
        let(:filter_autocomplete_fields) do
          [{ 'name' => 'ticket.customer_id', 'autocompleteFilterType' => 'customer' }]
        end
        let(:data) { { 'filters' => [filter_row('ticket.customer_id', customer.id)] } }

        it 'resolves a non-array value just like a single-element array' do
          expect(filter_options('ticket.customer_id')).to contain_exactly(hash_including(value: customer.id))
        end
      end

      context 'with an unknown id' do
        let(:filter_autocomplete_fields) do
          [{ 'name' => 'ticket.owner_id', 'autocompleteFilterType' => 'agent' }]
        end
        let(:data) { { 'filters' => [filter_row('ticket.owner_id', [9_999_999])] } }

        it 'omits the row entirely rather than emitting an empty options list' do
          expect(filter_options('ticket.owner_id')).to be_nil
        end
      end

      context 'when the matching row is missing from data' do
        let(:filter_autocomplete_fields) do
          [{ 'name' => 'ticket.owner_id', 'autocompleteFilterType' => 'agent' }]
        end
        let(:data) { { 'filters' => [] } }

        it 'silently skips it' do
          expect(updater.resolve[:fields]).to eq({})
        end
      end

      context 'with an unknown autocompleteFilterType' do
        let(:filter_autocomplete_fields) do
          [{ 'name' => 'ticket.weird_id', 'autocompleteFilterType' => 'nonsense' }]
        end
        let(:data) { { 'filters' => [filter_row('ticket.weird_id', [1])] } }

        it 'silently skips it' do
          expect(updater.resolve[:fields]).to eq({})
        end
      end

      context 'with a foreign-entity autocomplete row on a Ticket form' do
        let(:filter_autocomplete_fields) do
          [{ 'name' => 'user.organization_id', 'autocompleteFilterType' => 'organization' }]
        end
        let(:data) { { 'filters' => [filter_row('user.organization_id', [organization.id])] } }

        it 'drops the foreign-entity entry' do
          expect(updater.resolve[:fields]).to eq({})
        end
      end

      context 'with relation and autocomplete entries side by side' do
        let(:filter_relation_fields) { [{ 'name' => 'ticket.state_id', 'relation' => 'TicketState' }] }
        let(:filter_autocomplete_fields) do
          [{ 'name' => 'ticket.owner_id', 'autocompleteFilterType' => 'agent' }]
        end
        let(:data) { { 'filters' => [filter_row('ticket.owner_id', [other_agent.id])] } }

        it 'collects options for both kinds under filterAttributeOptions' do
          keys = updater.resolve.dig(:fields, 'filters', :filterAttributeOptions)&.keys
          expect(keys).to contain_exactly('ticket.state_id', 'ticket.owner_id')
        end

        context 'when triggered as a non-initial form-updater run' do
          let(:meta) do
            {
              initial:         false,
              additional_data: {
                'entity'                   => entity,
                'filterRelationFields'     => filter_relation_fields,
                'filterAutocompleteFields' => filter_autocomplete_fields,
              },
            }
          end

          it 'skips relation resolution (option lists are stable) but keeps autocomplete prefill' do
            keys = updater.resolve.dig(:fields, 'filters', :filterAttributeOptions)&.keys
            expect(keys).to contain_exactly('ticket.owner_id')
          end
        end
      end
    end
  end
end
