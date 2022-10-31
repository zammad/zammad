# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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

    it 'does reduces the category options to and it also sets further required fields to mandatory and visible.' do
      before_it.call

      expect(page).to have_css('label', text: 'group_example')
      expect(page).to have_css('label', text: 'category')
      expect(page).to have_no_css('label', text: 'operating_system')
      expect(page).to have_no_css('label', text: 'software_used')

      # Select a other group value, to trigger core workflow.
      # TODO: add helper functions for new tech stack / mobile view
      find('label', text: 'group_example').sibling('.formkit-inner').click
      click('span', text: %r{value_2}i)

      wait_for_gql('shared/components/Form/graphql/queries/formUpdater.graphql', number: 2)

      operating_system = find('label', text: 'operating_system')
      operating_system.ancestor('.formkit-outer[data-required=true]')

      software_used = find('label', text: 'software_used')
      software_used.ancestor('.formkit-outer[data-required=true]')

      find('label', text: 'category').sibling('.formkit-inner').click

      expect(page).to have_css('div[role=option] span', text: 'Change request')
      find('div[role=option] span', text: 'Incident').sibling('.icon-chevron-right').click
      expect(page).to have_css('div[role=option] span', text: 'Hardware')
      find('div[role=option] span', text: 'Softwareproblem').sibling('.icon-chevron-right').click
      expect(page).to have_css('div[role=option] span', text: 'CRM')
    end
  end
end
