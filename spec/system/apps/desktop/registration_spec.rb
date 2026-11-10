# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Registration', app: :desktop_view, authenticated_as: false, performs_jobs: true, type: :playwright do

  notification_url = ''

  before do
    allow(NotificationFactory::Mailer).to receive(:notification) do |params|
      notification_url = params[:objects][:url]
    end
  end

  it 'Register a new user and verify the email address with the confirmation link' do
    open_desktop('/login')

    page.get_by_role('link', name: 'Register', exact: true).click

    fill_field('First name', 'John')
    fill_field('Email', 'john.doe@example.com')
    fill_field('Password', 's3cr3tPassWord')
    fill_field('Confirm password', 's3cr3tPassWord')

    page.get_by_role('button', name: 'Create my account', exact: true).click

    expect(main_content).to contain_text('Thanks for joining. Email sent to "john.doe@example.com".')

    # The verification mail is delivered in the background.
    perform_enqueued_jobs only: NotificationMailerJob

    expect(notification_url).to be_present

    open_desktop("/#{notification_url.sub(%r{.*/desktop/}, '')}")

    expect(main_content).to contain_text('Woo hoo! Your email address has been verified!')
    expect(User.find_by(email: 'john.doe@example.com')).to be_verified
  end
end
