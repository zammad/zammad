require 'rails_helper'

RSpec.describe 'Ticket Update', type: :system do

  let(:group) { Group.find_by(name: 'Users') }

  # Regression test for issue #2242 - mandatory fields can be empty (or "-") on ticket update
  context 'when updating a ticket without its required select attributes' do
    scenario 'frontend checks reject the update', db_strategy: :reset do
      # setup and migrate a required select attribute
      attribute = create_attribute :object_manager_attribute_select,
                                   screens:     attributes_for(:required_screen),
                                   data_option: {
                                     options:    {
                                       'name 1': 'name 1',
                                       'name 2': 'name 2',
                                     },
                                     default:    '',
                                     null:       false,
                                     relation:   '',
                                     maxlength:  255,
                                     nulloption: true,
                                   }

      # create a new ticket and attempt to update its state without the required select attribute
      ticket = create :ticket, group: group
      visit "#ticket/zoom/#{ticket.id}"
      within(:active_content) do
        expect(page).to have_css('.js-objectNumber', wait: 2)

        select 'closed', from: 'state_id'
        click('.js-attributeBar .js-submit')
        expect(page).to have_no_css('.js-submitDropdown .js-submit[disabled]', wait: 2)
      end

      # the update should have failed and thus the ticket is still in the new state
      expect(ticket.reload.state.name).to eq('new')

      within(:active_content) do
        # update should work now
        find('.edit [name=internal_name1]').select('name 2')
        click('.js-attributeBar .js-submit')
        expect(page).to have_no_css('.js-submitDropdown .js-submit[disabled]', wait: 2)
      end

      ticket.reload
      expect(ticket[attribute.name]).to eq('name 2')
      expect(ticket.state.name).to eq('closed')
    end

    scenario 'with macro and required tree_select field', db_strategy: :reset do
      # setup and migrate a required select attribute
      attribute = create_attribute :object_manager_attribute_tree_select,
                                   screens:     attributes_for(:required_screen),
                                   data_option: {
                                     options:    [
                                       {
                                         name:  'name 1',
                                         value: 'name 1',
                                       },
                                       {
                                         name:  'name 2',
                                         value: 'name 2',
                                       },
                                     ],
                                     default:    '',
                                     null:       false,
                                     relation:   '',
                                     maxlength:  255,
                                     nulloption: true,
                                   }

      attribute_value = 'name 2'
      state           = Ticket::State.by_category(:closed).first
      macro           = create(:macro,
                               perform: {
                                 'ticket.state_id'          => {
                                   value: state.id,
                                 },
                                 "ticket.#{attribute.name}" => {
                                   value: attribute_value,
                                 },
                               })

      # refresh browser to get macro accessable
      page.driver.browser.navigate.refresh

      # create a new ticket and attempt to update its state without the required select attribute
      ticket = create(:ticket, group: group)
      visit "#ticket/zoom/#{ticket.id}"

      within(:active_content) do
        expect(page).to have_css('.js-objectNumber', wait: 2)

        click('.js-openDropdownMacro')
        click(".js-dropdownActionMacro[data-id=\"#{macro.id}\"]")
        expect(page).not_to have_css('.js-submitDropdown .js-submit[disabled]', wait: 2)
      end

      # the update should not have failed and thus the ticket is in closed state
      ticket.reload
      expect(ticket[attribute.name]).to eq(attribute_value)
      expect(ticket.state.name).to eq(state.name)
    end
  end
end
