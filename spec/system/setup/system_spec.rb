# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System setup process', authenticated_as: false, required_envs: %w[MAIL_ADDRESS MAIL_PASS], set_up: false, type: :system do

  def fqdn
    match_data = %r{://(.+?)(:.+?|/.+?|)$}.match(app_host)
    return match_data.captures.first if match_data.present?

    raise "Unable to get fqdn based on #{app_host}"
  end

  it 'Setting up a new system' do

    mailbox_user     = ENV['MAIL_ADDRESS']
    mailbox_password = ENV['MAIL_PASS']

    visit '/'

    expect(page).to have_css('.setup.wizard', text: 'Set up a new system')

    # choose setup (over migration)
    click_on('Set up a new system')

    # admin user form
    expect(page).to have_css('.js-admin h2', text: 'Administrator Account')

    within('.js-admin') do
      fill_in 'firstname',        with: 'Test Admin'
      fill_in 'lastname',         with: 'Agent'
      fill_in 'email',            with: 'admin@example.com'
      fill_in 'password',         with: 'TEst1234äöüß'
      fill_in 'password_confirm', with: 'TEst1234äöüß'

      click_on('Create')
    end

    # configure Organization
    expect(page).to have_css('.js-base h2', text: 'Organization')
    within('.js-base') do
      fill_in 'organization', with: 'Some Organization'

      # fill in wrong URL
      fill_in 'url', with: 'some host'
      click_on('Next')
      expect(page).to have_css('.alert', text: 'A URL looks like')

      # fill in valild/current URL
      fill_in 'url', with: app_host
      click_on('Next')
    end

    # configure Email Notification
    expect(page).to have_css('.js-outbound h2', text: 'Email Notification')
    expect_current_route 'getting_started/email_notification'
    click_on('Continue')

    # create email account
    expect(page).to have_css('.js-channel h2', text: 'Connect Channels')
    expect_current_route 'getting_started/channel'
    click('.js-channel .btn.email')

    within('.js-intro') do
      fill_in 'realname', with: 'Some Realname'
      fill_in 'email',    with: mailbox_user
      fill_in 'password', with: mailbox_password

      page.element.click_on('Connect')
    end

    # wait for verification process to start
    expect(page).to have_css('body', text: 'Verify sending and receiving')

    # wait for verification process to finish
    expect(page).to have_css('.js-agent h2', text: 'Invite Colleagues', wait: 2.minutes)
    expect_current_route 'getting_started/agents'

    # invite agent1
    within('.js-agent') do
      fill_in 'firstname', with: 'Agent 1'
      fill_in 'lastname',  with: 'Test'
      fill_in 'email',     with: 'agent12@example.com'

      click_on('Invite')
    end
    expect(page).to have_css('body', text: 'Invitation sent!')

    # expect to still be on the same page
    expect_current_route 'getting_started/agents'
    within('.js-agent') do
      click_on('Continue')
    end

    # expect Dashboard of a fresh system
    expect(page).to have_css('body', text: 'My Stats')
    expect_current_route 'clues'
    find(:clues_close).in_fixed_position.click

    # verify organization and fqdn
    click(:manage)

    within(:active_content) do

      click(:href, '#settings/branding')
      expect(page).to have_field('organization', with: 'Some Organization')

      click(:href, '#settings/system')
      expect(page).to have_field('fqdn', with: fqdn)
    end
  end

  # https://github.com/zammad/zammad/issues/3106
  it 'Shows an error message if too weak password is filled in' do
    visit '/'

    click_on('Set up a new system')

    within('.js-admin') do
      fill_in 'firstname',        with: 'Test Admin'
      fill_in 'lastname',         with: 'Agent'
      fill_in 'email',            with: 'admin@example.com'
      fill_in 'password',         with: 'asd'
      fill_in 'password_confirm', with: 'asd'

      click_on('Create')

      expect(page).to have_text 'Invalid password'
    end
  end
end
