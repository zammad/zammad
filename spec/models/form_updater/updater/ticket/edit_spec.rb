# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'models/form_updater/concerns/checks_core_workflow_examples'
require 'models/form_updater/concerns/has_security_options_examples'

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

  let(:group)   { create(:group) }
  let(:user)    { create(:agent, groups: [group]) }
  let(:context) { { current_user: user } }
  let(:meta)    { { initial: true, form_id: SecureRandom.uuid } }
  let(:data)    { {} }
  let(:id)      { nil }

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
      expect(resolved_result.resolve).to include(
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
        expect(resolved_result.resolve).to include(
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
          result = resolved_result.resolve
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
  end

  include_examples 'FormUpdater::ChecksCoreWorkflow', object_name: 'Ticket'
  include_examples 'HasSecurityOptions', type: 'edit'
end
