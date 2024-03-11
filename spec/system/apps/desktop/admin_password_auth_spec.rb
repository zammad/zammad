# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Admin Password Auth', app: :desktop_view, authenticated_as: false, type: :system do
  before do
    Setting.set('user_show_password_login', false)
    Setting.set('auth_github', true)
  end

  it 'Shows the regular password login after admin password auth request was sent' do
    visit '/login', skip_waiting: true

    expect(page).to have_no_field 'login'
    expect(page).to have_no_field 'password'

    click_on 'Request the password login here.'

    expect(page).to have_text 'Username'

    fill_in 'login', with: 'admin@example.com'
    click_on 'Submit'

    expect(page).to have_text 'Admin password login instructions were sent'

    token = Token.last
    visit "/login?token=#{token.token}"

    expect(page).to have_text 'The token is valid. You are now able to login via password once.'
    expect(page).to have_field 'login', disabled: :all
    expect(page).to have_field 'password'
  end
end
