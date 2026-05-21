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

  let(:group)                  { create(:group) }
  let(:user)                   { create(:agent, groups: [group]) }
  let(:context)                { { current_user: user } }
  let(:entity)                 { 'Ticket' }
  let(:filter_relation_fields) { [] }
  let(:meta)                   { { initial: true, additional_data: { 'entity' => entity, 'filterRelationFields' => filter_relation_fields } } }
  let(:data)                   { {} }

  def filter_options(name)
    updater.resolve.dig(:fields, 'filters', :filterAttributeOptions, name)
  end

  describe '#authorized?' do
    it 'is authorized for an agent on Ticket entity' do
      expect(updater.authorized?).to be true
    end

    context 'with customer + Ticket entity' do
      let(:user) { create(:customer) }

      it { expect(updater.authorized?).to be true }
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

      it 'silently skips it' do
        expect(updater.resolve[:fields]).to eq({})
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
  end
end
