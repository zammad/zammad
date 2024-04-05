# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Registration', app: :desktop_view, authenticated_as: false, type: :system do

  notification_url = ''

  before do
    allow(NotificationFactory::Mailer).to receive(:notification) do |params|
      notification_url = params[:objects][:url]
    end
  end

  it 'Register a new user and log in with the confirmation link' do
    visit '/login', skip_waiting: true

    click_on 'Register'

    fill_in 'First name', with: 'John'
    fill_in 'Last name',  with: 'Doe'
    fill_in 'Email', with: 'john.doe@example.com'
    fill_in 'Password', with: 's3cr3tPassWord'
    fill_in 'Confirm password', with: 's3cr3tPassWord'

    click_on 'Create my account'

    expect(page).to have_text('Thanks for joining. Email sent to "john.doe@example.com".')

    expect(notification_url).to be_present
    visit notification_url.sub(%r{.*/desktop/}, '')

    expect_current_route '/'

    wait_for_test_flag('useSessionUserStore.getCurrentUser.loaded')
  end
end
