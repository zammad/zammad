# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'models/form_updater/concerns/checks_core_workflow_examples'
require 'models/form_updater/concerns/has_security_options_examples'
require 'models/form_updater/concerns/applies_ticket_shared_draft_examples'
require 'models/form_updater/concerns/stores_taskbar_state_examples'
require 'models/form_updater/concerns/applies_taskbar_state_examples'

RSpec.describe(FormUpdater::Updater::Ticket::Edit) do
  subject(:resolved_result) do
    described_class.new(
      context:         context,
      relation_fields: relation_fields,
      meta:            meta,
      data:            data,
      id:              id,
    )
  end

  let(:group)        { create(:group) }
  let(:user)         { create(:agent, groups: [group]) }
  let(:context)      { { current_user: user } }
  let(:meta)         { { initial: true, form_id: SecureRandom.uuid, dirty_fields: } }
  let(:data)         { {} }
  let(:dirty_fields) { [] }
  let(:id)           { nil }

  let(:relation_fields) do
    [
      {
        name:     'group_id',
        relation: 'group',
      },
      {
        name:     'state_id',
        relation: 'TicketState',
      },
      {
        name:     'priority_id',
        relation: 'TicketPriority',
      },
    ]
  end

  let(:expected_result) do
    {
      'group_id'    => {
        options: [ { value: group.id, label: group.name } ],
      },
      'state_id'    => {
        options: Ticket::State.by_category(:viewable_agent_edit).reorder(name: :asc).map { |state| { value: state.id, label: state.name } },
      },
      'priority_id' => {
        options: Ticket::Priority.where(active: true).reorder(id: :asc).map { |priority| { value: priority.id, label: priority.name } },
      },
    }
  end

  context 'when resolving' do
    it 'returns all resolved relation fields with correct value + label' do
      expect(resolved_result.resolve[:fields]).to include(
        'group_id'    => include(expected_result['group_id']),
        'state_id'    => include(expected_result['state_id']),
        'priority_id' => include(expected_result['priority_id']),
      )
    end

    context 'when body is used' do
      before do
        create(:core_workflow, object:  'Ticket',
                               perform: {
                                 body: {
                                   operator:     'set_readonly',
                                   set_readonly: true
                                 },
                               })
      end

      it 'body (and also attachments) should be disabled' do
        expect(resolved_result.resolve[:fields]).to include(
          'body'        => include({
                                     disabled: true,
                                   }),
          'attachments' => include({
                                     disabled: true,
                                   }),
        )
      end
    end

    context 'when ticket has object attribute value with a historical value', db_strategy: :reset do
      let(:field_name) { SecureRandom.uuid }
      let(:screens) do
        {
          create_middle: {
            '-all-' => {
              shown:    true,
              required: false,
            },
          },
          create:        {
            '-all-' => {
              shown:    true,
              required: false,
            },
          },
          edit:          {
            '-all-' => {
              shown:    true,
              required: false,
            },
          },
        }
      end
      let(:object_attribute_field_type) { :object_manager_attribute_select }
      let(:object_attribute) do
        create(object_attribute_field_type, object_name: 'Ticket', name: field_name, display: field_name, screens: screens)
      end
      let(:ticket_object_attribute_value) { 'key_3' }

      let(:id) do
        Gql::ZammadSchema.id_from_object(create(:ticket, group: group, object_attribute.name => ticket_object_attribute_value))
      end

      before do
        object_attribute
        ObjectManager::Attribute.migration_execute
        object_attribute.reload
      end

      shared_examples 'resolve fields' do
        it 'checks that "rejectNonExistentValues" is false' do
          # Trigger first object authorization check.
          resolved_result.authorized?
          result = resolved_result.resolve[:fields]
          expect(result[field_name]).to include(expected_result)
        end
      end

      context 'when object attribute is a select field' do
        before do
          object_attribute.update!(data_option: object_attribute[:data_option].merge({ options: { key_1: 'value_1', key_2: 'value_2' } }))
          ObjectManager::Attribute.migration_execute
        end

        let(:expected_result) do
          {
            options:                 [
              {
                value: 'key_1',
                label: 'value_1',
              },
              {
                value: 'key_2',
                label: 'value_2',
              },
            ],
            clearable:               true,
            rejectNonExistentValues: false
          }
        end

        include_examples 'resolve fields'
      end

      context 'when object attribute is a tree select field' do
        let(:object_attribute_field_type)   { :object_manager_attribute_tree_select }
        let(:ticket_object_attribute_value) { 'Incident::Softwareproblem::MS Office' }
        let(:expected_result) do
          {
            options:                 [
              {
                label:    'Incident',
                value:    'Incident',
                disabled: false,
                children: [
                  {
                    label:    'Hardware',
                    value:    'Incident::Hardware',
                    disabled: false,
                    children: [
                      {
                        label:    'Monitor',
                        value:    'Incident::Hardware::Monitor',
                        disabled: false,
                      },
                      {
                        label:    'Mouse',
                        value:    'Incident::Hardware::Mouse',
                        disabled: false,
                      },
                    ]
                  },
                ]
              },
              {
                label:    'Change request',
                value:    'Change request',
                disabled: false,
              }
            ],
            clearable:               true,
            rejectNonExistentValues: false
          }
        end

        before do
          object_attribute.update!(data_option: object_attribute[:data_option].merge({ options: [
                                                                                       {
                                                                                         'name'     => 'Incident',
                                                                                         'value'    => 'Incident',
                                                                                         'children' => [
                                                                                           {
                                                                                             'name'     => 'Hardware',
                                                                                             'value'    => 'Incident::Hardware',
                                                                                             'children' => [
                                                                                               {
                                                                                                 'name'  => 'Monitor',
                                                                                                 'value' => 'Incident::Hardware::Monitor'
                                                                                               },
                                                                                               {
                                                                                                 'name'  => 'Mouse',
                                                                                                 'value' => 'Incident::Hardware::Mouse'
                                                                                               },
                                                                                             ]
                                                                                           },
                                                                                         ]
                                                                                       },
                                                                                       {
                                                                                         'name'  => 'Change request',
                                                                                         'value' => 'Change request'
                                                                                       }
                                                                                     ] }))
          ObjectManager::Attribute.migration_execute
        end

        include_examples 'resolve fields'
      end
    end

    context 'when time accounting should be triggered' do
      let(:id) do
        Gql::ZammadSchema.id_from_object(create(:ticket, group: group))
      end

      before do
        Setting.set('time_accounting', true)
      end

      it 'checks that time_accounting flag is not present' do
        # Trigger first object authorization check.
        resolved_result.authorized?

        # Time accounting check was moved into a separate validator, the flag should be absent.
        flags = resolved_result.resolve[:flags]
        expect(flags).not_to have_key(:time_accounting)
      end
    end

    context 'when auto save should be applied', :aggregate_failures do
      let(:taskbar_key)     { 'TicketZoom-1234' }
      let(:taskbar)         { create(:taskbar, key: taskbar_key, callback: 'Ticket', user_id: user.id, state: taskbar_state) }
      let(:taskbar_state)   { { 'ticket' => { 'title' => 'test', 'owner_id' => 1 } } }
      let(:field_name)      { 'title' }
      let(:field_result)    { { value: 'test' } }
      let(:additional_data) { { 'taskbarId' => Gql::ZammadSchema.id_from_object(taskbar), 'applyTaskbarState' => true } }
      let(:meta)            { { additional_data:, dirty_fields: } }

      let(:id) do
        Gql::ZammadSchema.id_from_object(create(:ticket, title: 'Example ticket', group: group, priority_id: 1))
      end

      before do
        # Trigger first object authorization check.
        resolved_result.authorized?
      end

      it 'owner_id should be nil for system user' do
        fields = resolved_result.resolve[:fields]
        expect(fields['owner_id'][:value]).to be_nil
      end

      context 'when apply should reset to default field value but field was changed' do
        let(:taskbar_state) { { 'ticket' => {} } }
        let(:dirty_fields) { %w[priority_id title] }

        it 'priority_id should be present for reset of default' do
          fields = resolved_result.resolve[:fields]
          expect(fields['priority_id'][:value]).to eq(1)
        end

        context 'with partial reseted fields' do
          let(:taskbar_state) { { 'ticket' => { 'priority_id' => 2 } } }

          it 'priority_id should be present for reset of default' do
            fields = resolved_result.resolve[:fields]
            expect(fields['priority_id'][:value]).to eq(2)
            expect(fields['title'][:value]).to eq('Example ticket')
          end
        end
      end

      context 'when new article exists' do
        let(:taskbar_state) { { 'ticket' => { 'title' => 'test' }, 'article' => { 'articleType' => 'email' } } }

        it 'checks that newArticlePresent flag is present' do
          flags = resolved_result.resolve[:flags]
          expect(flags[:newArticlePresent]).to be_truthy

          fields = resolved_result.resolve[:fields]
          expect(fields['title'][:value]).to eq('test')
        end
      end
    end

    context 'when data should be stored' do
      let(:taskbar_key)     { 'TicketZoom-1234' }
      let(:taskbar)         { create(:taskbar, key: taskbar_key, callback: 'Ticket', user_id: user.id) }
      let(:additional_data) { { 'taskbarId' => Gql::ZammadSchema.id_from_object(taskbar) } }
      let(:meta)            { { additional_data: } }

      let(:id) do
        Gql::ZammadSchema.id_from_object(create(:ticket, group: group, state_id: 1))
      end

      shared_examples 'stores the form value of the field' do
        it 'checks that data was stored correctly' do
          # Trigger first object authorization check.
          resolved_result.authorized?

          resolved_result.resolve
          state = taskbar.reload.state

          expect(state).to include(result)
        end
      end

      context 'when new article is saved' do
        let(:result)          { { 'ticket' => include({ 'title' => 'test' }), 'article' => { 'type' => 'email' } } }
        let(:data)            { { 'title' => 'test', 'article' => { 'articleType' => 'email' } } }

        include_examples 'stores the form value of the field'
      end

      context 'when data should be skipped' do
        let(:data)            { { 'title' => 'test', 'state_id' => 1 } }
        let(:result)          { { 'ticket' => { 'title' => 'test' } } }

        include_examples 'stores the form value of the field'
      end
    end
  end

  include_examples 'FormUpdater::ChecksCoreWorkflow', object_name: 'Ticket'
  include_examples 'FormUpdater::HasSecurityOptions', type: 'edit'
  include_examples 'FormUpdater::AppliesTicketSharedDraft', draft_type: 'detail-view'

  context 'when data should be stored and applied' do
    let(:id) do
      Gql::ZammadSchema.id_from_object(create(:ticket, group: group))
    end

    before do
      # Trigger creation of the ticket and handover the id.
      id

      # Trigger first object authorization check.
      resolved_result.authorized?
    end

    include_examples 'FormUpdater::StoresTaskbarState', taskbar_key: 'TicketZoom-1234', taskbar_callback: 'Ticket', store_state_collect_group_key: 'ticket', store_state_group_keys: ['article'] # gitleaks:allow
    include_examples 'FormUpdater::AppliesTaskbarState', taskbar_key: 'TicketZoom-1234', taskbar_callback: 'Ticket', apply_state_group_keys: %w[ticket article] # gitleaks:allow
  end
end
