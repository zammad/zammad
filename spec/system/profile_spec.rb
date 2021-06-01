# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Profile', type: :system do

  it 'shows profile link in navigation' do
    visit 'dashboard'

    find('a[href="#current_user"]').click
    expect(page).to have_css('.dropdown-menu > li > a[href="#profile"]')
  end

  context 'when user is an agent with no user_preferences permission', authenticated_as: :new_user do
    let(:role)            { create(:role, permissions: [Permission.find_by(name: 'ticket.agent')]) }
    let(:new_user)        { create(:user, roles: [role] ) }

    it 'does not show profile link in navigation' do
      visit 'dashboard'

      find('a[href="#current_user"]').click
      expect(page).to have_no_css('.dropdown-menu > li > a[href="#profile"]')
    end
  end
end
