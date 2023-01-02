# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'ChecksCoreWorkflow' do |object_name:|
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
  let(:object_attribute_field_type) { :object_manager_attribute_text }
  let(:core_workflow_perform_field) { nil }

  shared_examples 'resolve fields' do |expected_result:|
    it 'checks that mapping was correct' do
      result = resolved_result.resolve

      expect(result[field_name]).to include(expected_result)
    end
  end

  context 'when core workflow validation will be mapped', db_strategy: :reset do
    before do
      create(object_attribute_field_type, object_name: object_name, name: field_name, display: field_name, screens: screens)
      ObjectManager::Attribute.migration_execute

      if core_workflow_perform_field
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name}.#{field_name}": core_workflow_perform_field,
               })
      end
    end

    context 'when field is visible' do
      let(:core_workflow_perform_field) do
        {
          operator: 'show',
          show:     true
        }
      end

      include_examples 'resolve fields', expected_result: { show: true, hidden: false }
    end

    context 'when field should be hidden' do
      let(:core_workflow_perform_field) do
        {
          operator: 'hide',
          hide:     true
        }
      end

      include_examples 'resolve fields', expected_result: { show: true, hidden: true }
    end

    context 'when field should be hidden it should not be required' do
      let(:core_workflow_perform_field) do
        {
          operator:      %w[hide set_mandatory],
          hide:          true,
          set_mandatory: true,
        }
      end

      include_examples 'resolve fields', expected_result: { show: true, hidden: true, required: false }
    end

    context 'when field should be removed' do
      let(:core_workflow_perform_field) do
        {
          operator: 'remove',
          remove:   true,
        }
      end

      include_examples 'resolve fields', expected_result: { show: false }
    end

    context 'when field is not required' do
      let(:core_workflow_perform_field) do
        {
          operator:     'set_optional',
          set_optional: true
        }
      end

      include_examples 'resolve fields', expected_result: { required: false }
    end

    context 'when field is required' do
      let(:core_workflow_perform_field) do
        {
          operator:      'set_mandatory',
          set_mandatory: true
        }
      end

      include_examples 'resolve fields', expected_result: { required: true }
    end

    context 'when field is readonly' do
      let(:core_workflow_perform_field) do
        {
          operator:     'set_readonly',
          set_readonly: true
        }
      end

      include_examples 'resolve fields', expected_result: { disabled: true }
    end

    context 'when field is not readonly' do
      let(:core_workflow_perform_field) do
        {
          operator:       'unset_readonly',
          unset_readonly: true
        }
      end

      include_examples 'resolve fields', expected_result: { disabled: false }
    end

    context 'when field value should be changed' do
      context 'with a text field' do
        let(:core_workflow_perform_field) do
          {
            operator: 'fill_in',
            fill_in:  'hello'
          }
        end

        include_examples 'resolve fields', expected_result: { value: 'hello' }
      end

      context 'with a select field' do
        let(:object_attribute_field_type) { :object_manager_attribute_select }
        let(:core_workflow_perform_field) do
          {
            operator: 'select',
            select:   'key_3'
          }
        end

        include_examples 'resolve fields', expected_result: { value: 'key_3' }
      end
    end

    context 'when field options needs to be handled' do
      let(:object_attribute_field_type) { :object_manager_attribute_select }

      context 'when clearable should be present' do
        include_examples 'resolve fields', expected_result: { clearable: true }
      end

      context 'when select options are handled (without clearable)' do
        let(:core_workflow_perform_field) do
          {
            operator:     'set_fixed_to',
            set_fixed_to: %w[key_2 key_3],
          }
        end

        include_examples 'resolve fields', expected_result: {
          options:   [
            {
              value: 'key_2',
              label: 'value_2',
            },
            {
              value: 'key_3',
              label: 'value_3',
            }
          ],
          clearable: false
        }
      end

      context 'when multi select options are handled' do
        let(:object_attribute_field_type) { :object_manager_attribute_multiselect }
        let(:core_workflow_perform_field) do
          {
            operator:     'set_fixed_to',
            set_fixed_to: %w[key_2 key_3],
          }
        end

        include_examples 'resolve fields', expected_result: {
          options: [
            {
              value: 'key_2',
              label: 'value_2',
            },
            {
              value: 'key_3',
              label: 'value_3',
            }
          ]
        }
      end

      context 'when treeselect options are handled' do
        let(:object_attribute_field_type) { :object_manager_attribute_tree_select }
        let(:core_workflow_perform_field) do
          {
            operator:     'set_fixed_to',
            set_fixed_to: ['Incident::Hardware', 'Incident::Softwareproblem::CRM', 'Change request'],
          }
        end

        include_examples 'resolve fields', expected_result: {
          options: [
            {
              label:    'Incident',
              value:    'Incident',
              disabled: true,
              children: [
                {
                  label:    'Hardware',
                  value:    'Incident::Hardware',
                  disabled: false,
                },
                {
                  label:    'Softwareproblem',
                  value:    'Incident::Softwareproblem',
                  disabled: true,
                  children: [
                    {
                      label:    'CRM',
                      value:    'Incident::Softwareproblem::CRM',
                      disabled: false,
                    },
                  ]
                }
              ]
            },
            {
              label:    'Change request',
              value:    'Change request',
              disabled: false,
            }
          ]
        }
      end

      context 'when multi treeselect options are handled' do
        let(:object_attribute_field_type) { :object_manager_attribute_multi_tree_select }
        let(:core_workflow_perform_field) do
          {
            operator:     'set_fixed_to',
            set_fixed_to: ['Incident::Hardware', 'Incident::Softwareproblem::CRM', 'Change request'],
          }
        end

        include_examples 'resolve fields', expected_result: {
          options: [
            {
              label:    'Incident',
              value:    'Incident',
              disabled: true,
              children: [
                {
                  label:    'Hardware',
                  value:    'Incident::Hardware',
                  disabled: false,
                },
                {
                  label:    'Softwareproblem',
                  value:    'Incident::Softwareproblem',
                  disabled: true,
                  children: [
                    {
                      label:    'CRM',
                      value:    'Incident::Softwareproblem::CRM',
                      disabled: false,
                    },
                  ]
                }
              ]
            },
            {
              label:    'Change request',
              value:    'Change request',
              disabled: false,
            }
          ]
        }
      end

      context 'when boolean field is used' do
        let(:object_attribute_field_type) { :object_manager_attribute_boolean }

        include_examples 'resolve fields', expected_result: {
          options: [
            {
              label: 'yes',
              value: 'true',
            },
            {
              label: 'no',
              value: 'false',
            }
          ],
        }
      end
    end
  end
end
