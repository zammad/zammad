require 'rails_helper'

RSpec.describe 'Ticket Create', type: :system do

  let(:group) { Group.find_by(name: 'Users') }

  # Regression test for issue #2242 - mandatory fields can be empty (or "-") on ticket update
  context 'when updating a ticket without its required select attributes' do
    scenario 'frontend checks reject the update', db_strategy: :reset do
      # setup and migrate a required select attribute
      attribute = create_attribute :object_manager_attribute_select,
                                   screens: attributes_for(:required_screen)

      # create a new ticket and attempt to update its state without the required select attribute
      ticket = create :ticket, group: group
      visit "#ticket/zoom/#{ticket.id}"
      select 'closed', from: 'state_id'
      click('.content.active .js-attributeBar .js-submit')
      expect(page).to have_css('.content.active')

      # the update should have failed and thus the ticket is still in the new state
      expect(ticket.reload.state.name).to eq('new')
    end
  end
end
