# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'core workflow' do
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

  describe 'Workflow - Grouping specific values and fields', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_select, object_name: object_name, name: 'group_example', display: 'group_example', screens: screens)
      create(:object_manager_attribute_text, object_name: object_name, name: 'operating_system', display: 'operating_system', screens: screens)
      create(:object_manager_attribute_tree_select, object_name: object_name, name: 'category', display: 'category', screens: screens)
      create(:object_manager_attribute_select,
             object_name:             object_name,
             name:                    'software_used',
             display:                 'software_used',
             screens:                 screens,
             additional_data_options: { options: { 'software1' => 'Software1 1', 'software2' => 'Software 2', 'software3' => 'Software 3' } })

      ObjectManager::Attribute.migration_execute
      true
    end

    before do
      create(:core_workflow,
             object:  object_name,
             perform: {
               "#{object_name.downcase}.operating_system": {
                 operator: 'remove',
                 remove:   true
               },
               "#{object_name.downcase}.software_used":    {
                 operator: 'remove',
                 remove:   true
               },
             })
      create(:core_workflow,
             object:             object_name,
             condition_selected: {
               "#{object_name.downcase}.group_example": {
                 operator: 'is',
                 value:    'key_2',
               },
             },
             perform:            {
               "#{object_name.downcase}.operating_system": {
                 operator:      %w[show set_mandatory],
                 show:          true,
                 set_mandatory: true
               },
               "#{object_name.downcase}.software_used":    {
                 operator:      %w[show set_mandatory],
                 show:          true,
                 set_mandatory: true
               },
               "#{object_name.downcase}.category":         {
                 operatwor:    'set_fixed_to',
                 set_fixed_to: ['Incident::Hardware', 'Incident::Softwareproblem::CRM', 'Change request'],
               }
             })
    end

    it 'reduces the category options and sets further required fields to mandatory and visible' do
      before_it.call

      expect(page).to have_css('label', text: 'group_example')
      expect(page).to have_css('label', text: 'category')
      expect(page).to have_no_css('label', text: 'operating_system')
      expect(page).to have_no_css('label', text: 'software_used')

      within_form(form_updater_gql_number: form_updater_gql_number) do

        # Select another group value, to trigger core workflow.
        find_select('group_example').select_option('value_2')

        expect(find_input('operating_system')['data-required']).to eq('true')
        expect(find_select('software_used')['data-required']).to eq('true')

        category = find_treeselect('category')

        category.select_option('Change request')
        expect(category).to have_selected_option('Change request')

        category.select_option('Incident::Hardware')
        expect(category).to have_selected_option_with_parent('Incident::Hardware')

        category.select_option('Incident::Softwareproblem::CRM')
        expect(category).to have_selected_option_with_parent('Incident::Softwareproblem::CRM')
      end
    end
  end
end
