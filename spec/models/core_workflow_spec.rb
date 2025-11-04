# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/core_workflow/base'

RSpec.describe CoreWorkflow, type: :model do
  include_context 'with core workflow base'

  describe '.perform - No assets' do
    let(:result) { described_class.perform(payload: payload, user: action_user, assets: false) }

    it 'does not contain assets' do
      expect(result[:assets]).to be_blank
    end
  end

  describe '.matches_selector?' do
    let(:result) { described_class.matches_selector?(id: ticket.id, user: action_user, selector: condition) }

    context 'when matching open tickets' do
      let(:condition) do
        { 'ticket.state_id'=>{ 'operator' => 'is', 'value' => Ticket::State.by_category(:open).map { |x| x.id.to_s } } }
      end

      it 'does match' do
        expect(result).to be(true)
      end
    end

    context 'when matching closed tickets' do
      let(:condition) do
        { 'ticket.state_id'=>{ 'operator' => 'is', 'value' => Ticket::State.by_category(:closed).map { |x| x.id.to_s } } }
      end

      it 'does not match' do
        expect(result).to be(false)
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
    let!(:workflow_just_changed) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.priority_id': {
                 operator: 'just_changed',
               },
             })
    end
    let!(:workflow_just_changed_to) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.priority_id': {
                 operator: 'just_changed_to',
                 value:    [ Ticket::Priority.find_by(name: '3 high').id.to_s ]
               },
             })
    end

    context 'when priority changed' do
      let(:payload) do
        base_payload.merge('last_changed_attribute' => 'priority_id', 'params' => { 'priority_id' => Ticket::Priority.find_by(name: '3 high').id.to_s })
      end

      it 'does match on condition has changed' do
        expect(result[:matched_workflows]).to include(workflow_just_changed.id)
      end

      it 'does match on condition changed to' do
        expect(result[:matched_workflows]).to include(workflow_just_changed_to.id)
      end
    end

    context 'when nothing changed' do
      it 'does not match on condition has changed' do
        expect(result[:matched_workflows]).not_to include(workflow_just_changed.id)
      end

      it 'does not match on condition changed to' do
        expect(result[:matched_workflows]).not_to include(workflow_just_changed_to.id)
      end
    end

    context 'when state changed' do
      let(:payload) do
        base_payload.merge('last_changed_attribute' => 'state_id')
      end

      it 'does not match on condition has changed' do
        expect(result[:matched_workflows]).not_to include(workflow_just_changed.id)
      end

      it 'does not match on condition changed to' do
        expect(result[:matched_workflows]).not_to include(workflow_just_changed_to.id)
      end
    end
  end

  describe 'Wrong core workflow execution because of missing relation defaults #4541' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.priority_id': {
                 operator: 'is',
                 value:    [ Ticket::Priority.find_by(name: '1 low').id.to_s ]
               },
             })
    end

    before do
      Ticket::Priority.find_by(name: '2 normal').update(note: 'Test')
      workflow
    end

    it 'does not execute the core workflow because the default priority is 2 normal and not 1 low' do
      expect(result[:matched_workflows]).not_to include(workflow.id)
    end
  end

  describe 'Core Workflow - Action "Fill text if empty" will always be executed even if text field is not empty #4825' do
    let(:payload) do
      base_payload.merge('params' => { 'article' => { 'body' => 'test123' } })
    end
    let!(:workflow) do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.body': {
                 operator:      'fill_in_empty',
                 fill_in_empty: 'test',
               },
             })
    end

    before do
      workflow
    end

    it 'does not prefill if body is set already' do
      expect(result[:fill_in]['body']).to be_blank
    end
  end

  describe 'Core-Workflows: Removing groups with re-adding some discards all permissions the user has #5002' do
    let(:payload) do
      base_payload.merge('params' => { 'group_id' => Group.first.id })
    end
    let!(:workflow1) do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator:      'remove_option',
                 remove_option: Group.all.map { |x| x.id.to_s },
               },
             })
    end
    let!(:workflow2) do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator:   'add_option',
                 add_option: [Group.first.id.to_s],
               },
             })
    end

    before do
      action_user.group_names_access_map = {
        Group.first.name => %w[full],
      }
      workflow1
      workflow2
    end

    it 'does readd the group' do
      expect(result[:restrict_values]['group_id']).to eq(['', Group.first.id.to_s])
    end

    it 'does keep owners' do
      expect(result[:restrict_values]['owner_id']).to include(action_user.id.to_s)
    end

    it 'does not endless loop because of removing and adding the same element' do
      expect(result[:rerun_count]).to be < CoreWorkflow::Result::MAX_RERUN
    end
  end

  describe 'The default value of a boolean ticket object is not recognized correctly by Core Workflows when creating a ticket. #5670', db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
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

    context 'when select field' do
      let!(:workflow1) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: { "ticket.#{field_name}" => { 'operator' => 'is', 'value' => ['jx'] } })
      end

      before do
        create(:object_manager_attribute_select, name: field_name, display: field_name, screens: screens, data_option: { 'options' => [{ value: 'nx', name: 'nx' }, { value: 'jx', name: 'jx' }], 'default' => 'jx', 'linktemplate' => '', 'translate' => false, 'null' => true, 'relation' => '', 'nulloption' => false, 'maxlength' => 255, 'historical_options' => { 'jx' => 'jx', 'nx' => 'nx' } })
        ObjectManager::Attribute.migration_execute
      end

      it 'does match because the default value is used in the background' do
        expect(result[:matched_workflows]).to include(workflow1.id)
      end
    end

    context 'when boolean field' do
      let!(:workflow1) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: { "ticket.#{field_name}" => { 'operator' => 'is', 'value' => ['true'] } })
      end

      before do
        create(:object_manager_attribute_boolean, name: field_name, display: field_name, screens: screens, data_option: { 'options' => { false => 'nx', true => 'jx' }, 'default' => true, 'translate' => false, 'null' => true, 'relation' => '' })
        ObjectManager::Attribute.migration_execute
      end

      it 'does match because the default value is used in the background' do
        expect(result[:matched_workflows]).to include(workflow1.id)
      end
    end
  end
end
