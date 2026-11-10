# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require_relative '../../../../lib/zammad/service/redis'

RSpec.describe 'Desktop > Guided Setup', app: :desktop_view, authenticated_as: false, integration: true, required_envs: %w[MAIL_ADDRESS MAIL_PASS], set_up: false, type: :playwright do

  before do
    # Import mail server CA certificate into the trust store.
    SSLCertificate.create!(certificate: Rails.root.join('spec/fixtures/files/imap/ca.crt').read)

    allow(NotificationFactory::Mailer).to receive(:notification)
  end

  after do
    # Make sure lock is lifted even on test errors.
    Zammad::Service::Redis.new.del('Zammad::System::Setup')
  end

  def button(name)
    page.get_by_role('button', name:, exact: true)
  end

  it 'Perform the basic system set-up' do
    open_desktop('/')

    button('Set up a new system').click

    expect(page.get_by_label('First name', exact: true)).to be_visible(timeout: 30_000)

    # Invalid password
    fill_field('First name', 'John')
    fill_field('Last name', 'Doe')
    fill_field('Email', 'john.doe@example.com')
    fill_field('Password', '1234')
    fill_field('Confirm password', '1234')
    button('Create account').click

    expect(main_content).to contain_text('Invalid password')

    # Valid password, create account
    fill_field('Password', 'testTEST1234')
    fill_field('Confirm password', 'testTEST1234')
    button('Create account').click

    fill_field('Organization name', 'Test corp.')
    file_chooser = page.expect_file_chooser { button('Upload image').click }
    file_chooser.set_files(Rails.root.join('test/data/image/1000x1000.png').to_s)
    fill_field('System URL', PlaywrightNative::AppServer.url)
    button('Save and continue').click

    # Accept default setting (local MTA).
    expect(page.get_by_role('heading', name: 'Email notification', level: 1)).to be_visible
    button('Save and continue').click

    button('Email channel').click
    fill_field('Full name', 'John Doe')
    fill_field('Email address', ENV['MAIL_ADDRESS'])
    fill_field('Password', ENV['MAIL_PASS'])
    button('Connect and continue').click

    expect(main_content).to contain_text('Verifying and saving your configuration…')

    expect(page.get_by_role('heading', name: 'Invite colleagues', level: 1)).to be_visible(timeout: 2.minutes.in_milliseconds)

    fill_field('First name', 'Jim')
    fill_field('Last name', 'Doe')
    fill_field('Email', 'jim.doe@example.com')
    button('Send invitation').click
    expect(notification('Invitation sent!')).to be_visible

    button('Finish setup').click

    expect(page).to have_url(%r{/desktop/$})

    expect(NotificationFactory::Mailer).to have_received(:notification).once

    # TODO: check for "clues" in UI, not available yet.
  end
end
