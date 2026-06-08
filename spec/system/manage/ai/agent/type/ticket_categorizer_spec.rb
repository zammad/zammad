# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'AI > AI Agents > Types > Ticket Categorizer', db_strategy: :reset, type: :system do
  before do
    setup_ai_provider('open_ai', token: ENV['OPEN_AI_TOKEN'])

    create(:object_manager_attribute_select, name: 'example_category', display: 'Example Category')
    create(:object_manager_attribute_select, name: 'example_industry', display: 'Example Industry')
    ObjectManager::Attribute.migration_execute(false)
  end

  context 'when a new AI agent is created' do
    it 'allows selecting Ticket Categorizer type' do
      visit '#ai/ai_agents'

      click_on 'New AI Agent'

      in_modal do
        expect(page).to have_text('New: AI Agent')

        # Step 1: Fill in basic information and select agent type.
        fill_in 'name', with: 'Test Agent'
        set_select_field_label('agent_type', 'Ticket Categorizer')

        click_on 'Next'

        # Step 2: Select attribute.
        set_select_field_label('type_enrichment_data::category', 'Example Industry')

        click_on 'Next'

        # Step 3: Select attributes and provide descriptions.
        expect(page).to have_text('All categories will be considered for categorizing tickets.')

        click 'label', text: 'LIMIT CATEGORIES'
        expect(page).to have_no_text('All categories will be considered for categorizing tickets.')
          .and have_text('AVAILABLE CATEGORIES')
          .and have_text('EXAMPLE INDUSTRY')

        tree_select_field = page.find(%( .searchableSelect-shadow+.js-input )) # search input
          .click                                                               # focus
          .ancestor('.controls', order: :reverse, match: :first)               # find container

        tree_select_field.find("[data-display-name='value_1']")
          .click

        find('textarea.js-descriptionNew').set('Description for value_1')

        find('.js-add').click

        expect(page).to have_text('value_1')
          .and have_field(type: 'textarea', with: 'Description for value_1')

        click_on 'Next'

        click_on 'Submit'
      end

      expect(page).to have_text('Test Agent')

      expect(AI::Agent.last).to have_attributes(
        name:       'Test Agent',
        agent_type: 'TicketCategorizer',
        definition: {
          'instruction_context' => {
            'object_attributes' => {
              'placeholder.category' => {
                'key_1' => 'Description for value_1',
              },
            },
          },
        },
        active:     true,
      )

      # Check edit functionality.
      click "tr[data-id='#{AI::Agent.last.id}']"

      in_modal do
        # Step 1: Check the name and the selected agent type.
        expect(page).to have_text('Edit: AI Agent')
          .and have_field('name', with: 'Test Agent')
          .and have_select('agent_type', selected: 'Ticket Categorizer', disabled: true)

        click_on 'Next'

        # Step 2: Check selected attribute.
        expect(page).to have_select('type_enrichment_data::category', selected: 'Example Industry')

        click_on 'Next'

        # Step 3: Check selected attributes and descriptions.
        expect(page).to have_text('AVAILABLE CATEGORIES')
          .and have_text('value_1')
          .and have_field(type: 'textarea', with: 'Description for value_1')

        click_on 'Next'

        # Step 4: Check meta data.
        expect(page).to have_text('For this agent to run, it needs to be used in an automation (e.g. trigger, scheduler, macro).')
      end
    end
  end
end
