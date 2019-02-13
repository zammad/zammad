require 'rails_helper'

RSpec.describe 'Ticket Update', type: :system do

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

  # Issue #2469 - Add information "Ticket merged" to History
  context 'when merging tickets' do
    scenario 'tickets history of both tickets should show the merge event' do
      user = create :user
      origin_ticket = create :ticket, group: group
      target_ticket = create :ticket, group: group
      origin_ticket.merge_to(ticket_id: target_ticket.id, user_id: user.id)

      visit "#ticket/zoom/#{origin_ticket.id}"
      click '.content.active .js-actions .dropdown-toggle'
      click '.content.active .js-actions .dropdown-menu [data-type="ticket-history"]'

      modal = find('.content.active .modal')
      expect(modal).to have_content "This ticket was merged into ticket ##{target_ticket.number}"
      expect(modal).to have_link "##{target_ticket.number}", href: "#ticket/zoom/#{target_ticket.id}"

      visit "#ticket/zoom/#{target_ticket.id}"
      click '.content.active .js-actions .dropdown-toggle'
      click '.content.active .js-actions .dropdown-menu [data-type="ticket-history"]'

      modal = find('.content.active .modal')
      expect(modal).to have_content("Ticket ##{origin_ticket.number} was merged into this ticket")
      expect(modal).to have_link "##{origin_ticket.number}", href: "#ticket/zoom/#{origin_ticket.id}"
    end
  end
end
