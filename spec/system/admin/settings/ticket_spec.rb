require 'rails_helper'

RSpec.describe 'Admin > Settings > Ticket', type: :system do

  describe 'owner auto-assignment admin settings' do
    it 'enable and disable feature' do

      click(:manage)

      within(:active_content) do
        click(:href, '#settings/ticket')
        click(:href, '#auto_assignment')
        expect(page).to have_field('ticket_auto_assignment', checked: false, visible: false)
        find('.js-ticketAutoAssignment').click()
        expect(page).to have_field('ticket_auto_assignment', checked: true, visible: false)
      end

      refresh

      within(:active_content) do
        find('a[href="#auto_assignment"]').click()
        expect(page).to have_field('ticket_auto_assignment', checked: true, visible: false)
        find('.js-ticketAutoAssignment').click()
        expect(page).to have_field('ticket_auto_assignment', checked: false, visible: false)
      end
    end
  end

end
