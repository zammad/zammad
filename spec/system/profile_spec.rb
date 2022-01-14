# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Profile', type: :system do

  it 'shows profile link in navigation' do
    visit 'dashboard'

    find('a[href="#current_user"]').click
    expect(page).to have_css('.dropdown-menu > li > a[href="#profile"]')
  end

  context 'when user is an agent with no user_preferences permission', authenticated_as: :new_user do
    let(:role)            { create(:role, permissions: [Permission.find_by(name: 'ticket.agent')]) }
    let(:new_user)        { create(:user, roles: [role]) }

    it 'does not show profile link in navigation' do
      visit 'dashboard'

      find('a[href="#current_user"]').click
      expect(page).to have_no_css('.dropdown-menu > li > a[href="#profile"]')
    end
  end

  context "Don't provide option to create API-Token if authentication via API token is disabled #3168" do
    before do
      visit 'profile'
    end

    it 'does show the navbar link Token Access based on the Setting api_token_access' do
      expect(page).to have_text('Token Access')

      # disable token access
      visit 'system/api'
      click 'label[for=api_token_access]'

      visit 'profile'
      expect(page).to have_no_text('Token Access')

      # enable token access
      visit 'system/api'
      click 'label[for=api_token_access]'

      visit 'profile'
      expect(page).to have_text('Token Access')
    end
  end
end
