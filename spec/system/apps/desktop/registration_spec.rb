# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Registration', app: :desktop_view, authenticated_as: false, type: :system do

  notification_url = ''

  before do
    allow(NotificationFactory::Mailer).to receive(:notification) do |params|
      notification_url = params[:objects][:url]
    end
  end

  it 'Register a new user and log in with the confirmation link' do
    visit '/login'

    click_on 'Register'

    find_input('First name').type('John')
    find_input('Email').type('john.doe@example.com')
    find_input('Password').type('s3cr3tPassWord')
    find_input('Confirm password').type('s3cr3tPassWord')

    click_on 'Create my account'

    expect(page).to have_text('Thanks for joining. Email sent to "john.doe@example.com".')
    expect(notification_url).to be_present

    visit notification_url.sub(%r{.*/desktop/}, '')

    expect_current_route '/'
  end
end
