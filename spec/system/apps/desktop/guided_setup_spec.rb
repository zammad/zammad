# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Guided Setup', app: :desktop_view, authenticated_as: false, required_envs: %w[MAIL_ADDRESS MAIL_PASS], set_up: false, type: :system do

  before do
    # Import mail server CA certificate into the trust store.
    SSLCertificate.create!(certificate: Rails.root.join('spec/fixtures/files/imap/ca.crt').read)

    allow(NotificationFactory::Mailer).to receive(:notification)
  end

  after do
    # Make sure lock is lifted even on test errors.
    Redis.new(driver: :hiredis, url: ENV['REDIS_URL'].presence || 'redis://localhost:6379').del('Zammad::System::Setup')
  end

  it 'Perform the basic system set-up' do
    visit '/'

    click_on 'Set up a new system'

    # Invalid password
    fill_in 'First name', with: 'John'
    fill_in 'Last name', with: 'Doe'
    fill_in 'Email', with: 'john.doe@example.com'
    fill_in 'Password', with: '1234'
    fill_in 'Confirm password', with: '1234'
    click_on 'Create account'

    expect(page).to have_text('Invalid password')

    # Valid password, create account
    fill_in 'Password', with: 'testTEST1234'
    fill_in 'Confirm password', with: 'testTEST1234'
    click_on 'Create account'

    fill_in 'Organization name', with: 'Test corp.'
    find('input[name="logo"]', visible: :all).set(Rails.root.join('test/data/image/1000x1000.png'))
    fill_in 'System URL', with: app_host
    click_on 'Save and Continue'

    # Accept default setting (local MTA).
    expect(page).to have_text('Email Notification')
    click_on 'Save and Continue'

    click_on 'Email Channel'
    fill_in 'Full name', with: 'John Doe'
    fill_in 'Email address', with: ENV['MAIL_ADDRESS']
    fill_in 'Password', with: ENV['MAIL_PASS']
    click_on 'Connect and Continue'

    expect(page).to have_text('Verifying and saving your configuration…')

    expect(page).to have_text('Invite Colleagues', wait: 2.minutes)

    fill_in 'First name', with: 'Jim'
    fill_in 'Last name', with: 'Doe'
    fill_in 'Email', with: 'jim.doe@example.com'
    click_on 'Send Invitation'
    expect(page).to have_text('Invitation sent!')

    click_on('Finish Setup')

    expect(NotificationFactory::Mailer).to have_received(:notification).once

    expect_current_route('/')

    # TODO: check for "clues" in UI, not available yet.
  end
end
