require 'rails_helper'

RSpec.describe 'System setup process', type: :system, set_up: false do

  def fqdn
    match_data = %r{://(.+?)(:.+?|/.+?|)$}.match(app_host)
    return match_data.captures.first if match_data.present?

    raise "Unable to get fqdn based on #{app_host}"
  end

  it 'Setting up a new system', authenticated: false do

    if !ENV['MAILBOX_INIT']
      skip("NOTICE: Need MAILBOX_INIT as ENV variable like export MAILBOX_INIT='unittest01@znuny.com:somepass'")
    end
    mailbox_user     = ENV['MAILBOX_INIT'].split(':')[0]
    mailbox_password = ENV['MAILBOX_INIT'].split(':')[1]

    visit '/'

    expect(page).to have_css('.setup.wizard', text: 'Setup new System')

    # choose setup (over migration)
    click_on('Setup new System')

    # admin user form
    expect(page).to have_css('.js-admin h2', text: 'Administrator Account')

    within('.js-admin') do
      fill_in 'firstname',        with: 'Test Master'
      fill_in 'lastname',         with: 'Agent'
      fill_in 'email',            with: 'master@example.com'
      fill_in 'password',         with: 'test1234äöüß'
      fill_in 'password_confirm', with: 'test1234äöüß'

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

      click_on('Connect')
    end

    # wait for verification process to start
    expect(page).to have_css('body', text: 'Verify sending and receiving', wait: 20)

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
    find(:clues_close, wait: 4).in_fixed_postion.click

    # verify organization and fqdn
    click(:manage)

    within(:active_content) do

      click(:href, '#settings/branding')
      expect(page).to have_field('organization', with: 'Some Organization')

      click(:href, '#settings/system')
      expect(page).to have_field('fqdn', with: fqdn)
    end
  end
end
