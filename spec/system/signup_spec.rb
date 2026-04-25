# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Signup', authenticated_as: false, type: :system do

  notification_url = ''

  before do
    allow(NotificationFactory::Mailer).to receive(:notification) do |params|
      notification_url = params[:objects][:url]
    end
    visit 'signup'
  end

  it 'creates an account successfully' do
    fill_in 'firstname',        with: 'Test'
    fill_in 'lastname',         with: 'Test'
    fill_in 'email',            with: 'test@example.com'
    fill_in 'password',         with: 'SOme-pass1'
    fill_in 'password_confirm', with: 'SOme-pass1'

    click '.js-submit'

    expect(page).to have_css '.signup', text: 'Registration successful!'
    expect(notification_url).to be_present

    visit notification_url

    expect_current_route 'ticket/view/my_tickets'
  end

  it 'with a weak password show password strength error' do
    fill_in 'firstname',        with: 'Test'
    fill_in 'lastname',         with: 'Test'
    fill_in 'email',            with: 'test@example.com'
    fill_in 'password',         with: 'asdasdasdasd'
    fill_in 'password_confirm', with: 'asdasdasdasd'

    click '.js-submit'

    within '.js-danger' do
      expect(page).to have_text('Invalid password,').and(have_no_text('["'))
    end
  end
end
