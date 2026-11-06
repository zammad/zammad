# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Favorite', app: :mobile, type: :playwright do
  describe 'overview configuration' do
    let(:included_overviews) { main_content.get_by_role('list', name: 'Included ticket overviews').get_by_role('listitem') }

    before do
      create(:overview, name: 'Test Overview')
      open_mobile('/')
    end

    it 'user can change overview order' do
      main_content.get_by_role('link', name: 'Edit', exact: true).click
      expect(page).to have_url(%r{/mobile/favorite/ticket-overviews/edit$})

      # In this order, other overviews may sit in between.
      expect(included_overviews).to contain_text(['Test Overview', 'My Assigned Tickets'])

      included_overviews.filter(hasText: 'Test Overview').drag_to(included_overviews.filter(hasText: 'My Assigned Tickets'))

      expect(included_overviews).to contain_text(['My Assigned Tickets', 'Test Overview'])

      page.get_by_role('banner').get_by_role('button', name: 'Save', exact: true).click
      expect(notification('Ticket overview settings are saved.')).to be_visible

      expect(page).to have_url(%r{/mobile/$})
      expect(main_content).to contain_text(%r{My Assigned Tickets\s*0\s*Test Overview})
    end
  end
end
