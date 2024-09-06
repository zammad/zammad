# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Favorite', app: :mobile, type: :system do
  describe 'overview configuration' do
    before do
      create(:overview, name: 'Test Overview')
      visit '/'
    end

    it 'user can change overview order' do
      click_on 'Edit'
      expect_current_route('/favorite/ticket-overviews/edit')

      expect(page).to have_text("Test Overview\nMy Assigned Tickets")

      o1 = find('div[draggable=true]', text: 'Test Overview')
      o2 = find('div[draggable=true]', text: 'My Assigned Tickets')
      o1.drag_to(o2)

      expect(page).to have_text("My Assigned Tickets\nTest Overview")

      click_on 'Save'
      expect(page).to have_text('Ticket Overview settings are saved.')

      expect_current_route('/')
      expect(page).to have_text("My Assigned Tickets\n0\nTest Overview")
    end
  end
end
