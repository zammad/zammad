# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/core_workflow/base'

RSpec.describe 'CoreWorkflow > Defaults', mariadb: true, type: :model do
  include_context 'with core workflow base'

  describe '.perform - Default - Group' do
    let!(:group_change) { create(:group) }
    let!(:group_create) { create(:group) }

    describe 'for agent with full permissions on screen create_middle' do
      let(:action_user) { create(:agent) }

      before do
        action_user.group_names_access_map = {
          group_create.name => ['full'],
          group_change.name => ['change'],
        }
      end

      it 'does show group_create for agent with all permissions' do
        expect(result[:restrict_values]['group_id']).to include(group_create.id.to_s)
      end

      it 'does not show group_change for agent with all permissions' do
        expect(result[:restrict_values]['group_id']).not_to include(group_change.id.to_s)
      end
    end

    describe 'for agent with full permissions on screen edit' do
      let(:payload) do
        base_payload.merge('screen' => 'edit')
      end
      let(:action_user) { create(:agent) }

      before do
        action_user.group_names_access_map = {
          group_create.name => ['full'],
          group_change.name => ['change'],
        }
      end

      it 'does show group_create for agent with all permissions' do
        expect(result[:restrict_values]['group_id']).to include(group_create.id.to_s)
      end

      it 'does show group_change for agent with all permissions' do
        expect(result[:restrict_values]['group_id']).to include(group_change.id.to_s)
      end
    end

    describe 'for agent with change permissions on screen create_middle' do
      let(:action_user) { create(:agent) }

      before do
        action_user.group_names_access_map = {
          group_create.name => ['change'],
          group_change.name => ['change'],
        }
      end

      it 'does not show group_create for agent with change permissions' do
        expect(result[:restrict_values]['group_id']).not_to include(group_create.id.to_s)
      end

      it 'does not show group_change for agent with change permissions' do
        expect(result[:restrict_values]['group_id']).not_to include(group_change.id.to_s)
      end
    end

    describe 'for agent with change permissions on screen edit' do
      let(:payload) do
        base_payload.merge('screen' => 'edit')
      end
      let(:action_user) { create(:agent) }

      before do
        action_user.group_names_access_map = {
          group_create.name => ['change'],
          group_change.name => ['change'],
        }
      end

      it 'does show group_create for agent with change permissions' do
        expect(result[:restrict_values]['group_id']).to include(group_create.id.to_s)
      end

      it 'does show group_change for agent with change permissions' do
        expect(result[:restrict_values]['group_id']).to include(group_change.id.to_s)
      end
    end

    describe 'for customer on screen create_middle' do
      let(:action_user) { create(:customer) }

      it 'does show group_create for customer' do
        expect(result[:restrict_values]['group_id']).to include(group_create.id.to_s)
      end

      it 'does show group_change for customer' do
        expect(result[:restrict_values]['group_id']).to include(group_change.id.to_s)
      end
    end

    describe 'for customer on screen edit' do
      let(:payload) do
        base_payload.merge('screen' => 'edit')
      end
      let(:action_user) { create(:customer) }

      it 'does show group_create for customer' do
        expect(result[:restrict_values]['group_id']).to include(group_create.id.to_s)
      end

      it 'does show group_change for customer' do
        expect(result[:restrict_values]['group_id']).to include(group_change.id.to_s)
      end
    end
  end

  describe '.perform - Default - Owner' do
    before do
      another_group = create(:group)

      action_user.group_names_access_map = {
        ticket.group.name  => ['full'],
        another_group.name => ['full'],
      }
    end

    it 'does not show any owners for no group' do
      expect(result[:restrict_values]['owner_id']).to eq([''])
    end

    describe 'on group' do
      let(:payload) do
        base_payload.merge('params' => { 'group_id' => ticket.group.id })
      end

      it 'does show ticket agent' do
        expect(result[:restrict_values]['owner_id']).to eq(['', action_user.id.to_s])
      end
    end

    describe 'on group save' do
      let(:payload) do
        base_payload.merge('request_id' => 'ChecksCoreWorkflow.validate_workflows', 'params' => { 'group_id' => ticket.group.id })
      end

      it 'does show ticket agent and system user' do
        expect(result[:restrict_values]['owner_id']).to eq(['', '1', action_user.id.to_s])
      end
    end
  end

  describe '.perform - Default - Bulk Owner' do
    let(:payload) do
      base_payload.merge('screen' => 'overview_bulk')
    end

    it 'does not show any owners for no group' do
      expect(result[:restrict_values]['owner_id']).to eq([''])
    end

    describe 'on ticket ids' do
      let(:payload) do
        base_payload.merge('screen' => 'overview_bulk', 'params' => { 'ticket_ids' => ticket.id.to_s })
      end

      it 'does show ticket agent' do
        expect(result[:restrict_values]['owner_id']).to eq(['', action_user.id.to_s])
      end
    end

    describe 'on ticket ids with no group overlap' do
      let(:ticket2) { create(:ticket) }
      let(:payload) do
        base_payload.merge('screen' => 'overview_bulk', 'params' => { 'ticket_ids' => "#{ticket.id},#{ticket2.id}" })
      end

      it 'does not show ticket agent' do
        expect(result[:restrict_values]['owner_id']).to eq([''])
      end
    end

    describe 'on ticket ids with group overlap' do
      let(:ticket2) { create(:ticket, group: ticket.group) }
      let(:payload) do
        base_payload.merge('screen' => 'overview_bulk', 'params' => { 'ticket_ids' => "#{ticket.id},#{ticket2.id}" })
      end

      it 'does show ticket agent' do
        expect(result[:restrict_values]['owner_id']).to eq(['', action_user.id.to_s])
      end
    end

    describe 'Ticket owner selection is not updated if owner selection should be empty #3809' do
      let(:group_no_owners) { create(:group) }
      let(:ticket2) { create(:ticket, group: group_no_owners) }
      let(:payload) do
        base_payload.merge('screen' => 'overview_bulk', 'params' => { 'ticket_ids' => ticket2.id.to_s })
      end

      before do
        action_user.group_names_access_map = {
          group_no_owners.name => %w[create read change overview],
        }
      end

      it 'does not show any owners for group with no full permitted users' do
        expect(result[:restrict_values]['owner_id']).to eq([''])
      end
    end
  end

  describe '.perform - Default - State' do
    it 'does show state type new for create_middle' do
      expect(result[:restrict_values]['state_id']).to include(Ticket::State.find_by(name: 'new').id.to_s)
    end

    describe 'on edit' do
      let(:payload) do
        base_payload.merge('screen' => 'edit')
      end

      it 'does not show state type new' do
        expect(result[:restrict_values]['state_id']).not_to include(Ticket::State.find_by(name: 'new').id.to_s)
      end
    end

    it 'does show empty value for create_middle' do
      expect(result[:restrict_values]['state_id']).to include('')
    end

    context 'with customer user' do
      let(:action_user) { create(:customer) }

      it 'does not show empty value for create_middle' do
        expect(result[:restrict_values]['state_id']).not_to include('')
      end
    end
  end

  describe '.perform - Default - Priority' do
    let(:prio_invalid) { create(:ticket_priority, active: false) }

    it 'does show valid priority' do
      expect(result[:restrict_values]['priority_id']).to include(Ticket::Priority.find_by(name: '3 high').id.to_s)
    end

    it 'does not show invalid priority' do
      expect(result[:restrict_values]['priority_id']).not_to include(prio_invalid.id.to_s)
    end
  end

  describe '.perform - Default - Customer setting customer_ticket_create_group_ids' do
    let(:action_user) { create(:customer) }

    let!(:group1) { create(:group) }
    let!(:group2) { create(:group) }
    let!(:group3) { create(:group) }

    it 'does show group 1' do
      expect(result[:restrict_values]['group_id']).to include(group1.id.to_s)
    end

    context 'with customer_ticket_create_group_ids set' do
      before do
        Setting.set('customer_ticket_create_group_ids', [group2.id.to_s, group3.id.to_s])
      end

      it 'does not show group 1' do
        expect(result[:restrict_values]['group_id']).not_to include(group1.id.to_s)
      end
    end
  end

  describe '.perform - Default - #3721 - Fields are falsey displayed as mandatory if they contain historic screen values', db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:screens) do
      {
        create_middle: {
          'ticket.agent' => {
            shown: true,
          },
        },
      }
    end

    before do
      create(:object_manager_attribute_text, object_name: 'Ticket', name: field_name, display: field_name, screens: screens)
      ObjectManager::Attribute.migration_execute
    end

    it 'does show the field as optional because it has no required value' do
      expect(result[:mandatory][field_name]).to be(false)
    end
  end

  describe '.perform - Default - Certain offered states can not be set (never) via the bulk action #4848' do
    let(:payload) do
      base_payload.merge('screen' => 'overview_bulk')
    end

    it 'does not show non-edit states in the bulk edit of the ticket overview' do
      expect(result[:restrict_values]['state_id']).not_to include(*Ticket::State.where(name: %w[new removed]).pluck(:id).map(&:to_s))
    end
  end
end
