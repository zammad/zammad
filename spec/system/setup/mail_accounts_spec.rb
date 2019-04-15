require 'rails_helper'

RSpec.describe 'Mail accounts', type: :system do

  def perform_check
    # getting started - auto mail
    visit 'getting_started/channel'

    click('.js-channel .btn.email')

    yield

    # wait for verification process to finish
    expect(page).to have_css('.js-agent h2', text: 'Invite Colleagues', wait: 4.minutes)

    expect_current_route 'getting_started/agents'
  end

  def fill_in_credentials(account)
    within('.js-intro') do

      fill_in 'realname', with: account[:realname]
      fill_in 'email',    with: account[:email]
      fill_in 'password', with: account[:password]

      click_on('Connect')
    end
  end

  it 'Auto detectable configurations' do

    skip('NOTICE: This test is currently disabled because of collisions with other non Capybara browser tests')

    accounts = (1..10).each_with_object([]) do |count, result|
      next if !ENV["MAILBOX_AUTO#{count}"]

      email, password = ENV["MAILBOX_AUTO#{count}"].split(':')
      result.push(
        realname: 'auto account',
        email:    email,
        password: password,
      )
    end

    if accounts.blank?
      skip("NOTICE: Need min. MAILBOX_AUTO1 as ENV variable like export MAILBOX_AUTO1='nicole.braun2015@gmail.com:somepass'")
    end

    accounts.each do |account|

      perform_check do
        fill_in_credentials(account)
      end
    end
  end

  it 'Manual configurations' do

    accounts = (1..10).each_with_object([]) do |count, result|
      next if !ENV["MAILBOX_MANUAL#{count}"]

      email, password, inbound, outbound = ENV["MAILBOX_MANUAL#{count}"].split(':')

      result.push(
        realname: 'manual account',
        email:    email,
        password: password,
        inbound:  {
          'options::host' => inbound,
        },
        outbound: {
          'options::host' => outbound,
        },
      )
    end

    if accounts.blank?
      skip("NOTICE: Need min. MAILBOX_MANUAL1 as ENV variable like export MAILBOX_MANUAL1='nicole.bauer2015@yahoo.de:somepass:imap.mail.yahoo.com:smtp.mail.yahoo.com'")
    end

    accounts.each do |account|

      perform_check do
        fill_in_credentials(account)

        within('.js-inbound') do

          expect(page).to have_css('h2', text: 'inbound', wait: 4.minutes)
          expect(page).to have_css('body', text: 'manual')

          fill_in 'options::host', with: account[:inbound]['options::host']

          click_on('Connect')
        end

        within('.js-outbound') do

          expect(page).to have_css('h2', text: 'outbound', wait: 4.minutes)

          select('SMTP - configure your own outgoing SMTP settings', from: 'adapter')

          fill_in 'options::host', with: account[:outbound]['options::host']

          click_on('Connect')
        end
      end
    end
  end
end
