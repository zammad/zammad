# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Settings > Ticket', type: :system do

  before { visit 'settings/ticket' }

  describe 'owner auto-assignment' do

    it 'enables/disables Setting ticket_auto_assignment' do

      within(:active_content) do
        click(:href, '#auto_assignment')
        expect(page).to have_field('ticket_auto_assignment', checked: false, visible: :hidden)
        find('.js-ticketAutoAssignment').click
        expect(page).to have_field('ticket_auto_assignment', checked: true, visible: :hidden)
      end

      refresh

      within(:active_content) do
        click(:href, '#auto_assignment')
        expect(page).to have_field('ticket_auto_assignment', checked: true, visible: :hidden)
        find('.js-ticketAutoAssignment').click
        expect(page).to have_field('ticket_auto_assignment', checked: false, visible: :hidden)
      end
    end
  end

end
