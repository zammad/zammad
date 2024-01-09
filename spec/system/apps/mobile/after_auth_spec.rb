# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > After Auth', :aggregate_failures, app: :mobile, authenticated_as: :agent, type: :system do
  let(:agent) { create(:agent) }

  before do
    allow_any_instance_of(Auth::AfterAuth::TwoFactorConfiguration).to receive(:check).and_return(true)
  end

  context 'when user is logged in, but after auth is required' do
    it 'requires setting up two factor auth' do
      visit '/', skip_waiting: true

      expect(page).to have_content('The two-factor authentication is not configured yet')
      expect_current_route '/login/after-auth'
    end
  end

  context 'when user is not authenticated, but 2FA is required', authenticated_as: false do
    it 'provides a link for setting up 2FA by using the desktop view' do
      allow_any_instance_of(Auth::AfterAuth::TwoFactorConfiguration).to receive(:check).and_return(true)

      visit '/', skip_waiting: true

      find_input('Username / Email').type(agent.login)
      find_input('Password').type('test')

      click_on('Sign in')

      expect(page).to have_content('The two-factor authentication is not configured yet')
      expect(page).to have_link('Click here to set up a two-factor authentication method.', href: '/#')

      click 'a', text: 'Click here to set up a two-factor authentication method.'
      expect_current_route('dashboard', app: :desktop)
      expect(page).to have_content('You must protect your account with two-factor authentication.')
    end
  end
end
