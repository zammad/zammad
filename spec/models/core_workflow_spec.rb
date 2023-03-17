# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CoreWorkflow, mariadb: true, type: :model do
  let(:group)   { create(:group) }
  let!(:ticket) { create(:ticket, state: Ticket::State.find_by(name: 'pending reminder'), pending_time: 5.days.from_now, group: group) }
  let!(:base_payload) do
    {
      'event'      => 'core_workflow',
      'request_id' => 'default',
      'class_name' => 'Ticket',
      'screen'     => 'create_middle',
      'params'     => {},
    }
  end
  let(:payload) { base_payload }
  let!(:action_user) { create(:agent, groups: [ticket.group]) }
  let(:result)       { described_class.perform(payload: payload, user: action_user) }

  describe '.perform - No assets' do
    let(:result) { described_class.perform(payload: payload, user: action_user, assets: false) }

    it 'does not contain assets' do
      expect(result[:assets]).to be_blank
    end
  end

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

  describe '.perform - Default - Restrict values for multiselect fields', db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }

    before do
      create(:object_manager_attribute_multiselect, name: field_name, display: field_name)
      ObjectManager::Attribute.migration_execute
    end

    context 'without saved values' do
      it 'does return the correct list of selectable values' do
        expect(result[:restrict_values][field_name]).to eq(['', 'key_1', 'key_2', 'key_3'])
      end
    end

    context 'with saved values' do
      let(:payload) do
        base_payload.merge('params' => {
                             'id' => ticket.id,
                           })
      end

      before do
        ticket.reload.update(field_name.to_sym => %w[key_2 key_3])
      end

      it 'does return the correct list of selectable values' do
        expect(result[:restrict_values][field_name]).to eq(['', 'key_1', 'key_2', 'key_3'])
      end
    end
  end

  describe '.perform - Custom - Pending Time' do
    it 'does not show pending time for non pending state' do
      expect(result[:visibility]['pending_time']).to eq('remove')
    end

    describe 'for ticket id with no state change' do
      let(:payload) do
        base_payload.merge('params' => {
                             'id' => ticket.id,
                           })
      end

      it 'does show pending time for pending ticket' do
        expect(result[:visibility]['pending_time']).to eq('show')
      end
    end

    describe 'for ticket id with state change' do
      let(:payload) do
        base_payload.merge('params' => {
                             'id'       => ticket.id,
                             'state_id' => Ticket::State.find_by(name: 'open').id.to_s,
                           })
      end

      it 'does not show pending time for pending ticket' do
        expect(result[:visibility]['pending_time']).to eq('remove')
      end
    end
  end

  describe '.perform - Custom - Admin SLA' do
    let(:payload) do
      base_payload.merge(
        'screen'     => 'edit',
        'class_name' => 'Sla',
      )
    end

    it 'does set first_response_time_in_text optional' do
      expect(result[:mandatory]['first_response_time_in_text']).to be(false)
    end

    it 'does set update_time_in_text optional' do
      expect(result[:mandatory]['update_time_in_text']).to be(false)
    end

    it 'does set solution_time_in_text optional' do
      expect(result[:mandatory]['solution_time_in_text']).to be(false)
    end

    describe 'on first_response_time_enabled' do
      let(:payload) do
        base_payload.merge(
          'screen'     => 'edit',
          'class_name' => 'Sla',
          'params'     => { 'first_response_time_enabled' => 'true' }
        )
      end

      it 'does set first_response_time_in_text mandatory' do
        expect(result[:mandatory]['first_response_time_in_text']).to be(true)
      end

      it 'does set update_time_in_text optional' do
        expect(result[:mandatory]['update_time_in_text']).to be(false)
      end

      it 'does set solution_time_in_text optional' do
        expect(result[:mandatory]['solution_time_in_text']).to be(false)
      end
    end

    describe 'on update_time_enabled' do
      let(:payload) do
        base_payload.merge(
          'screen'     => 'edit',
          'class_name' => 'Sla',
          'params'     => { 'update_time_enabled' => 'true', 'update_type' => 'update' }
        )
      end

      it 'does set first_response_time_in_text optional' do
        expect(result[:mandatory]['first_response_time_in_text']).to be(false)
      end

      it 'does set update_time_in_text mandatory' do
        expect(result[:mandatory]['update_time_in_text']).to be(true)
      end

      it 'does set solution_time_in_text optional' do
        expect(result[:mandatory]['solution_time_in_text']).to be(false)
      end
    end

    describe 'on solution_time_enabled' do
      let(:payload) do
        base_payload.merge(
          'screen'     => 'edit',
          'class_name' => 'Sla',
          'params'     => { 'solution_time_enabled' => 'true' }
        )
      end

      it 'does set first_response_time_in_text optional' do
        expect(result[:mandatory]['first_response_time_in_text']).to be(false)
      end

      it 'does set update_time_in_text optional' do
        expect(result[:mandatory]['update_time_in_text']).to be(false)
      end

      it 'does set solution_time_in_text mandatory' do
        expect(result[:mandatory]['solution_time_in_text']).to be(true)
      end
    end
  end

  describe '.perform - Custom - Admin CoreWorkflow' do
    let(:payload) do
      base_payload.merge(
        'screen'     => 'edit',
        'class_name' => 'CoreWorkflow',
      )
    end

    it 'does not show screens for empty object' do
      expect(result[:restrict_values]['preferences::screen']).to eq([''])
    end

    it 'does not show invalid objects' do
      expect(result[:restrict_values]['object']).not_to include('CoreWorkflow')
    end

    describe 'on object Ticket' do
      let(:payload) do
        base_payload.merge(
          'screen'     => 'edit',
          'class_name' => 'CoreWorkflow',
          'params'     => { 'object' => 'Ticket' },
        )
      end

      it 'does show screen create_middle' do
        expect(result[:restrict_values]['preferences::screen']).to include('create_middle')
      end

      it 'does show screen edit' do
        expect(result[:restrict_values]['preferences::screen']).to include('edit')
      end
    end

    describe 'on saved object Ticket' do
      let(:workflow) { create(:core_workflow, object: 'Ticket') }
      let(:payload) do
        base_payload.merge(
          'screen'     => 'edit',
          'class_name' => 'CoreWorkflow',
          'params'     => { 'id' => workflow.id },
        )
      end

      it 'does show screen create_middle' do
        expect(result[:restrict_values]['preferences::screen']).to include('create_middle')
      end

      it 'does show screen edit' do
        expect(result[:restrict_values]['preferences::screen']).to include('edit')
      end
    end
  end

  describe '.perform - Condition - owner_id not set' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.owner_id': {
                 operator: 'not_set',
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for owner id 1' do
      let(:payload) do
        base_payload.merge(
          'params' => { 'owner_id' => '1' },
        )
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - session.role_ids' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'session.role_ids': {
                 operator: 'is',
                 value:    [ Role.find_by(name: 'Agent').id.to_s ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for customer' do
      let!(:action_user) { create(:customer) } # rubocop:disable RSpec/LetSetup

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - session.group_ids_full' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'session.group_ids_full': {
                 operator: 'is',
                 value:    [ ticket.group.id.to_s ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for customer' do
      let!(:action_user) { create(:customer) } # rubocop:disable RSpec/LetSetup

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - session.group_ids_change' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'session.group_ids_change': {
                 operator: 'is',
                 value:    [ ticket.group.id.to_s ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for customer' do
      let!(:action_user) { create(:customer) } # rubocop:disable RSpec/LetSetup

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - session.group_ids_read' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'session.group_ids_read': {
                 operator: 'is',
                 value:    [ ticket.group.id.to_s ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for customer' do
      let!(:action_user) { create(:customer) } # rubocop:disable RSpec/LetSetup

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - session.group_ids_overview' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'session.group_ids_overview': {
                 operator: 'is',
                 value:    [ ticket.group.id.to_s ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for customer' do
      let!(:action_user) { create(:customer) } # rubocop:disable RSpec/LetSetup

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - session.group_ids_create' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'session.group_ids_create': {
                 operator: 'is',
                 value:    [ ticket.group.id.to_s ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for customer' do
      let!(:action_user) { create(:customer) } # rubocop:disable RSpec/LetSetup

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - session.permission_ids' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'session.permission_ids': {
                 operator: 'is',
                 value:    [ Permission.find_by(name: 'ticket.agent').id.to_s ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for customer' do
      let!(:action_user) { create(:customer) } # rubocop:disable RSpec/LetSetup

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - Regex match' do
    let(:payload) do
      base_payload.merge(
        'params' => { 'title' => 'workflow ticket' },
      )
    end
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.title': {
                 operator: 'regex match',
                 value:    [ '^workflow' ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for invalid regex' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'regex match',
                   value:    [ '^workfluw' ],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - Regex mismatch' do
    let(:payload) do
      base_payload.merge(
        'params' => { 'title' => 'workflow ticket' },
      )
    end
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.title': {
                 operator: 'regex mismatch',
                 value:    [ '^workfluw' ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for invalid regex' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'regex mismatch',
                   value:    [ '^workflow' ],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - Contains' do
    let(:payload) do
      base_payload.merge(
        'params' => { 'title' => 'workflow ticket' },
      )
    end
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.title': {
                 operator: 'contains',
                 value:    [ 'workflow ticket', 'workflaw ticket' ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for invalid value' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'contains',
                   value:    [ 'workfluw ticket', 'workflaw ticket' ],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - Contains not' do
    let(:payload) do
      base_payload.merge(
        'params' => { 'title' => 'workflow ticket' },
      )
    end
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.title': {
                 operator: 'contains not',
                 value:    [ 'workfluw ticket', 'workflaw ticket' ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for invalid value' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'contains not',
                   value:    [ 'workflow ticket', 'workflow ticket' ],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - Contains all' do
    let(:payload) do
      base_payload.merge(
        'params' => { 'title' => 'workflow ticket' },
      )
    end
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.title': {
                 operator: 'contains all',
                 value:    [ 'workflow ticket', 'workflow ticket' ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for invalid value' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'contains all',
                   value:    [ 'workflow ticket', 'workflaw ticket' ],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - Contains all not' do
    let(:payload) do
      base_payload.merge(
        'params' => { 'title' => 'workflow ticket' },
      )
    end
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.title': {
                 operator: 'contains all not',
                 value:    [ 'workfluw ticket', 'workflaw ticket' ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for invalid value' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'contains all not',
                   value:    [ 'workflow ticket', 'workflaw ticket' ],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Stop after match' do
    let(:stop_after_match) { false }

    before do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.priority_id': {
                 operator: 'hide',
                 hide:     'true'
               },
             })
      create(:core_workflow,
             object:           'Ticket',
             perform:          {
               'ticket.priority_id': {
                 operator: 'show',
                 show:     'true'
               },
             },
             stop_after_match: stop_after_match)
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.priority_id': {
                 operator: 'hide',
                 hide:     'true'
               },
             })
    end

    it 'does not stop' do
      expect(result[:visibility]['priority_id']).to eq('hide')
    end

    describe 'with stop_after_match' do
      let(:stop_after_match) { true }

      it 'does stop' do
        expect(result[:visibility]['priority_id']).to eq('show')
      end
    end
  end

  describe '.perform - Condition - Custom module' do
    let(:modules) { ['CoreWorkflow::Custom::Testa', 'CoreWorkflow::Custom::Testb', 'CoreWorkflow::Custom::Testc'] }
    let(:custom_class_false) do
      Class.new(CoreWorkflow::Custom::Backend) do
        def selected_attribute_match?
          false
        end
      end
    end
    let(:custom_class_true) do
      Class.new(CoreWorkflow::Custom::Backend) do
        def selected_attribute_match?
          true
        end
      end
    end
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'custom.module': {
                 operator: operator,
                 value:    modules,
               },
             })
    end

    describe 'with "match all modules" false' do
      let(:operator) { 'match all modules' }

      before do
        stub_const 'CoreWorkflow::Custom::Testa', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testb', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testc', custom_class_false
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    describe 'with "match all modules" true' do
      let(:operator) { 'match all modules' }

      before do
        stub_const 'CoreWorkflow::Custom::Testa', custom_class_true
        stub_const 'CoreWorkflow::Custom::Testb', custom_class_true
        stub_const 'CoreWorkflow::Custom::Testc', custom_class_true
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    describe 'with "match all modules" blank' do
      let(:modules)  { [] }
      let(:operator) { 'match all modules' }

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    describe 'with "match one module" true' do
      let(:operator) { 'match one module' }

      before do
        stub_const 'CoreWorkflow::Custom::Testa', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testb', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testc', custom_class_true
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    describe 'with "match one module" false' do
      let(:operator) { 'match one module' }

      before do
        stub_const 'CoreWorkflow::Custom::Testa', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testb', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testc', custom_class_false
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    describe 'with "match one module" blank' do
      let(:modules) { [] }
      let(:operator) { 'match one module' }

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    describe 'with "match no modules" true' do
      let(:operator) { 'match no modules' }

      before do
        stub_const 'CoreWorkflow::Custom::Testa', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testb', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testc', custom_class_false
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    describe 'with "match no modules" false' do
      let(:operator) { 'match no modules' }

      before do
        stub_const 'CoreWorkflow::Custom::Testa', custom_class_true
        stub_const 'CoreWorkflow::Custom::Testb', custom_class_true
        stub_const 'CoreWorkflow::Custom::Testc', custom_class_true
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    describe 'with "match no modules" blank' do
      let(:modules) { [] }
      let(:operator) { 'match no modules' }

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end
  end

  describe '.perform - Select' do
    let!(:workflow1) do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator: 'select',
                 select:   [ticket.group.id.to_s]
               },
             })
    end
    let!(:workflow2) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.group_id': {
                 operator: 'is',
                 value:    ticket.group.id.to_s
               },
             },
             perform:            {
               'ticket.owner_id': {
                 operator: 'select',
                 select:   [action_user.id.to_s]
               },
             })
    end

    it 'does match workflows' do
      expect(result[:matched_workflows]).to include(workflow1.id, workflow2.id)
    end

    it 'does select group' do
      expect(result[:select]['group_id']).to eq(ticket.group.id.to_s)
    end

    it 'does select owner (recursion)' do
      expect(result[:select]['owner_id']).to eq(action_user.id.to_s)
    end

    it 'does rerun 2 times (group select + owner select)' do
      expect(result[:rerun_count]).to eq(2)
    end
  end

  describe '.perform - Auto Select' do
    let!(:workflow1) do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator:    'auto_select',
                 auto_select: true
               },
             })
    end
    let!(:workflow2) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.group_id': {
                 operator: 'is',
                 value:    ticket.group.id.to_s
               },
             },
             perform:            {
               'ticket.owner_id': {
                 operator:    'auto_select',
                 auto_select: true
               },
             })
    end

    it 'does match workflows' do
      expect(result[:matched_workflows]).to include(workflow1.id, workflow2.id)
    end

    it 'does select group' do
      expect(result[:select]['group_id']).to eq(ticket.group.id.to_s)
    end

    it 'does select owner (recursion)' do
      expect(result[:select]['owner_id']).to eq(action_user.id.to_s)
    end

    it 'does rerun 2 times (group select + owner select)' do
      expect(result[:rerun_count]).to eq(2)
    end

    describe 'with owner' do
      let(:payload) do
        base_payload.merge('params' => {
                             'group_id' => ticket.group.id.to_s,
                             'owner_id' => action_user.id.to_s,
                           })
      end

      it 'does not select owner' do
        expect(result[:select]['owner_id']).to be_nil
      end

      it 'does rerun 0 times' do
        expect(result[:rerun_count]).to eq(0)
      end
    end
  end

  describe '.perform - Fill in' do
    let!(:workflow1) do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator: 'select',
                 select:   [ticket.group.id.to_s]
               },
             })
    end
    let!(:workflow2) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.group_id': {
                 operator: 'is',
                 value:    ticket.group.id.to_s
               },
             },
             perform:            {
               'ticket.title': {
                 operator: 'fill_in',
                 fill_in:  'hello'
               },
             })
    end

    it 'does match workflows' do
      expect(result[:matched_workflows]).to include(workflow1.id, workflow2.id)
    end

    it 'does select group' do
      expect(result[:select]['group_id']).to eq(ticket.group.id.to_s)
    end

    it 'does fill in title' do
      expect(result[:fill_in]['title']).to eq('hello')
    end

    it 'does rerun 1 time (group select + title fill in)' do
      expect(result[:rerun_count]).to eq(1)
    end
  end

  describe '.perform - Fill in empty' do
    let!(:workflow1) do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator: 'select',
                 select:   [ticket.group.id.to_s]
               },
             })
    end
    let!(:workflow2) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.group_id': {
                 operator: 'is',
                 value:    ticket.group.id.to_s
               },
             },
             perform:            {
               'ticket.title': {
                 operator:      'fill_in_empty',
                 fill_in_empty: 'hello'
               },
             })
    end

    it 'does match workflows' do
      expect(result[:matched_workflows]).to include(workflow1.id, workflow2.id)
    end

    it 'does select group' do
      expect(result[:select]['group_id']).to eq(ticket.group.id.to_s)
    end

    it 'does fill in title' do
      expect(result[:fill_in]['title']).to eq('hello')
    end

    it 'does rerun 1 time (group select + title fill in)' do
      expect(result[:rerun_count]).to eq(1)
    end

    describe 'with title' do
      let(:payload) do
        base_payload.merge('params' => {
                             'title' => 'ha!',
                           })
      end

      it 'does not fill in title' do
        expect(result[:fill_in]['title']).to be_nil
      end

      it 'does rerun 1 times (group select)' do
        expect(result[:rerun_count]).to eq(1)
      end
    end
  end

  describe '.perform - Rerun attributes default cache bug' do
    before do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator: 'select',
                 select:   [ticket.group.id.to_s]
               },
             })
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.group_id': {
                 operator: 'is_set',
               },
             },
             perform:            {
               'ticket.owner_id': {
                 operator: 'select',
                 select:   [action_user.id.to_s]
               },
             })
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.owner_id': {
                 operator: 'not_set',
               },
             },
             perform:            {
               'ticket.priority_id': {
                 operator: 'hide',
                 hide:     'true'
               },
             })
    end

    it 'does not hide priority id' do
      expect(result[:visibility]['priority_id']).to eq('show')
    end
  end

  describe '.perform - Clean up params after restrict values removed selected value by set_fixed_to' do
    let(:payload) do
      base_payload.merge('params' => {
                           'owner_id' => action_user.id,
                         })
    end

    before do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator: 'select',
                 select:   [ticket.group.id.to_s]
               },
             })
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.group_id': {
                 operator: 'is_set',
               },
             },
             perform:            {
               'ticket.owner_id': {
                 operator:     'set_fixed_to',
                 set_fixed_to: ['']
               },
             })
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.owner_id': {
                 operator: 'is_set',
               },
             },
             perform:            {
               'ticket.priority_id': {
                 operator: 'hide',
                 hide:     'true'
               },
             })
    end

    it 'does not allow owner_id' do
      expect(result[:restrict_values]['owner_id']).not_to include(action_user.id)
    end

    it 'does not hide priority id' do
      expect(result[:visibility]['priority_id']).to eq('show')
    end
  end

  describe '.perform - Clean up params after restrict values removed selected value by remove_option' do
    let(:payload) do
      base_payload.merge('params' => {
                           'owner_id' => action_user.id,
                         })
    end

    before do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator: 'select',
                 select:   [ticket.group.id.to_s]
               },
             })
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.group_id': {
                 operator: 'is_set',
               },
             },
             perform:            {
               'ticket.owner_id': {
                 operator:      'remove_option',
                 remove_option: [action_user.id]
               },
             })
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.owner_id': {
                 operator: 'is_set',
               },
             },
             perform:            {
               'ticket.priority_id': {
                 operator: 'hide',
                 hide:     'true'
               },
             })
    end

    it 'does not allow owner_id' do
      expect(result[:restrict_values]['owner_id']).not_to include(action_user.id)
    end

    it 'does not hide priority id' do
      expect(result[:visibility]['priority_id']).to eq('show')
    end
  end

  describe '.perform - Clean up params after restrict values removed selected value by default attributes' do
    let(:payload) do
      base_payload.merge('params' => {
                           'owner_id' => action_user.id,
                         })
    end

    before do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.owner_id': {
                 operator: 'is_set',
               },
             },
             perform:            {
               'ticket.priority_id': {
                 operator: 'hide',
                 hide:     'true'
               },
             })
    end

    it 'does not allow owner_id' do
      expect(result[:restrict_values]['owner_id']).not_to include(action_user.id)
    end

    it 'does not hide priority id' do
      expect(result[:visibility]['priority_id']).to eq('show')
    end
  end

  describe '.perform - Default - auto selection based on only_shown_if_selectable' do
    it 'does auto select group' do
      expect(result[:select]['group_id']).not_to be_nil
    end

    it 'does auto hide group' do
      expect(result[:visibility]['group_id']).to eq('hide')
    end
  end

  describe '.perform - One field and two perform actions' do
    before do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.owner_id': {
                 operator:     %w[select set_optional],
                 select:       [action_user.id.to_s],
                 set_optional: 'true',
               },
             })
    end

    it 'does auto select owner' do
      expect(result[:select]['owner_id']).to eq(action_user.id.to_s)
    end

    it 'does set owner optional' do
      expect(result[:mandatory]['owner_id']).to be(false)
    end
  end

  describe '.perform - Hide mobile based on user login' do
    let(:base_payload) do
      {
        'event'      => 'core_workflow',
        'request_id' => 'default',
        'class_name' => 'User',
        'screen'     => 'create',
        'params'     => {
          'login' => 'nicole.special@zammad.org',
        },
      }
    end

    before do
      create(:core_workflow,
             object:             'User',
             condition_selected: { 'user.login'=>{ 'operator' => 'is', 'value' => 'nicole.special@zammad.org' } },
             perform:            { 'user.mobile'=>{ 'operator' => 'hide', 'hide' => 'true' } },)
    end

    it 'does hide mobile for user' do
      expect(result[:visibility]['mobile']).to eq('hide')
    end
  end

  describe '.perform - Condition - group active is true' do
    let(:payload) do
      base_payload.merge('params' => {
                           'group_id' => Group.first.id,
                         })
    end

    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: { 'group.active'=>{ 'operator' => 'is', 'value' => true } })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end
  end

  describe '.perform - Condition - group.assignment_timeout (Integer) matches' do
    let(:group) { create(:group, assignment_timeout: 10) }
    let(:payload) do
      base_payload.merge('params' => {
                           'group_id' => group.id,
                         })
    end

    before do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: { 'group.assignment_timeout'=>{ 'operator' => 'is', 'value' => 10 } },
             perform:            { 'ticket.priority_id'=>{ 'operator' => 'hide', 'hide' => 'true' } },)
    end

    it 'does match' do
      expect(result[:visibility]['priority_id']).to eq('hide')
    end
  end

  describe '.perform - Readonly' do
    let!(:workflow1) do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator:     'set_readonly',
                 set_readonly: 'true'
               },
             })
    end

    it 'does match workflow' do
      expect(result[:matched_workflows]).to include(workflow1.id)
    end

    it 'does set group readonly' do
      expect(result[:readonly]['group_id']).to be(true)
    end

    context 'when readonly unset' do
      let!(:workflow2) do
        create(:core_workflow,
               object:  'Ticket',
               perform: {
                 'ticket.group_id': {
                   operator:       'unset_readonly',
                   unset_readonly: 'true'
                 },
               })
      end

      it 'does match workflows' do
        expect(result[:matched_workflows]).to include(workflow1.id, workflow2.id)
      end

      it 'does set group readonly' do
        expect(result[:readonly]['group_id']).to be(false)
      end
    end
  end

  describe 'Core Workflow "is not" operator is working unexpected #3752' do
    let(:approval_role) { create(:role) }
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'session.role_ids': {
                 operator: 'is_not',
                 value:    [ approval_role.id.to_s ]
               },
             })
    end

    context 'when not action user has approval role' do
      let(:action_user) { create(:agent, roles: [Role.find_by(name: 'Agent'), approval_role]) }

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'when action user has not approval role' do
      let(:action_user) { create(:agent) }

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end
  end

  describe 'Saved conditions break on selections without reloading #3758', db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:screens) do
      {
        edit: {
          'ticket.agent' => {
            shown: true,
          },
        },
      }
    end
    let!(:workflow) do
      create(:core_workflow,
             object:          'Ticket',
             condition_saved: {
               "ticket.#{field_name}": {
                 operator: 'is_not',
                 value:    'true',
               },
             })
    end
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    before do
      create(:object_manager_attribute_boolean, object_name: 'Ticket', name: field_name, display: field_name, screens: screens)
      ObjectManager::Attribute.migration_execute
    end

    it 'does match the workflow because saved value is false' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    context 'when params contain boolean field true' do
      let(:payload) do
        base_payload.merge('params' => { 'id' => ticket.id, field_name => true }, 'screen' => 'edit')
      end

      it 'does match the workflow because saved value is false' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end
  end

  describe 'Core Workflow: Add organization condition attributes for object User #3779' do
    let(:organization) { create(:organization, note: 'hello') }
    let!(:base_payload) do
      {
        'event'      => 'core_workflow',
        'request_id' => 'default',
        'class_name' => 'User',
        'screen'     => 'create',
        'params'     => {},
      }
    end
    let!(:workflow) do
      create(:core_workflow,
             object:             'User',
             condition_selected: {
               'organization.note': {
                 operator: 'is',
                 value:    'hello',
               },
             })
    end

    context 'when new user has no organization' do
      it 'does not match the workflow' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'when new user is part of the organization' do
      let(:payload) do
        base_payload.merge('params' => { 'organization_id' => organization.id.to_s })
      end

      it 'does match the workflow' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end
  end

  describe 'Ticket owner selection is not updated if owner selection should be empty #3809' do
    let(:group_no_owners) { create(:group) }
    let(:payload) do
      base_payload.merge('params' => { 'group_id' => group_no_owners.id })
    end

    before do
      action_user.group_names_access_map = {
        group_no_owners.name => %w[create read change overview],
      }
    end

    it 'does not show any owners because no one has full permissions' do
      expect(result[:restrict_values]['owner_id']).to eq([''])
    end
  end

  describe 'If selected value is not part of the restriction of set_fixed_to it should recalculate it with the new value #3822', db_strategy: :reset do
    let(:field_name1) { SecureRandom.uuid }
    let(:screens) do
      {
        'create_middle' => {
          'ticket.agent' => {
            'shown'    => false,
            'required' => false,
          }
        }
      }
    end
    let!(:workflow1) do
      create(:core_workflow,
             object:  'Ticket',
             perform: { "ticket.#{field_name1}" => { 'operator' => 'set_fixed_to', 'set_fixed_to' => ['key_3'] } })
    end
    let!(:workflow2) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               "ticket.#{field_name1}": {
                 operator: 'is',
                 value:    'key_3',
               },
             })
    end

    before do
      create(:object_manager_attribute_select, name: field_name1, display: field_name1, screens: screens)
      ObjectManager::Attribute.migration_execute
    end

    it 'does select key_3 as new param value and based on this executes workflow 2' do
      expect(result[:matched_workflows]).to include(workflow1.id, workflow2.id)
    end
  end

  describe 'Add clear selection action or has changed condition #3821' do
    let!(:workflow_has_changed) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.priority_id': {
                 operator: 'has_changed',
               },
             })
    end
    let!(:workflow_changed_to) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.priority_id': {
                 operator: 'changed_to',
                 value:    [ Ticket::Priority.find_by(name: '3 high').id.to_s ]
               },
             })
    end

    context 'when priority changed' do
      let(:payload) do
        base_payload.merge('last_changed_attribute' => 'priority_id', 'params' => { 'priority_id' => Ticket::Priority.find_by(name: '3 high').id.to_s })
      end

      it 'does match on condition has changed' do
        expect(result[:matched_workflows]).to include(workflow_has_changed.id)
      end

      it 'does match on condition changed to' do
        expect(result[:matched_workflows]).to include(workflow_changed_to.id)
      end
    end

    context 'when nothing changed' do
      it 'does not match on condition has changed' do
        expect(result[:matched_workflows]).not_to include(workflow_has_changed.id)
      end

      it 'does not match on condition changed to' do
        expect(result[:matched_workflows]).not_to include(workflow_changed_to.id)
      end
    end

    context 'when state changed' do
      let(:payload) do
        base_payload.merge('last_changed_attribute' => 'state_id')
      end

      it 'does not match on condition has changed' do
        expect(result[:matched_workflows]).not_to include(workflow_has_changed.id)
      end

      it 'does not match on condition changed to' do
        expect(result[:matched_workflows]).not_to include(workflow_changed_to.id)
      end
    end
  end
end
