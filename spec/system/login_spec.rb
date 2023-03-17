# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Login', authenticated_as: false, type: :system do
  before do
    visit '/'
  end

  it 'fqdn is visible on login page' do
    expect(page).to have_css('.login p', text: Setting.get('fqdn'))
  end

  it 'Login with wrong credentials' do
    within('#login') do
      fill_in 'username', with: 'admin@example.com'
      fill_in 'password', with: 'wrong'

      click_button
    end

    expect(page).to have_css('#login .alert')
  end
end
