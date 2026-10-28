# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Automatic third-party login redirect', authenticated_as: false, type: :system do
  let(:agent)         { create(:agent) }
  let(:authorization) { create(:authorization, user: agent, provider: 'github', uid: '123456') }
  let(:ticket)        { create(:ticket, group: Group.first) }

  around do |example|
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider:    authorization.provider,
      uid:         authorization.uid,
      info:        {},
      credentials: {},
    )

    example.run
  ensure
    OmniAuth.config.mock_auth.delete(:github)
    OmniAuth.config.test_mode = false
  end

  before do
    agent.group_names_access_map = { Group.first.name => 'full' }

    Setting.set('user_show_password_login', false)
    Setting.set('auth_github', true)
    Setting.set('third_party_login_auto_redirect', true)
  end

  it 'signs in through the provider and opens the requested ticket' do
    visit "#ticket/zoom/#{ticket.id}"

    expect(page).to have_current_route("ticket/zoom/#{ticket.id}")
    expect(page).to have_text(ticket.title)
  end

  it 'stays on the login page after a logout' do
    visit "#ticket/zoom/#{ticket.id}"

    expect(page).to have_text(ticket.title)

    logout

    expect(page).to have_current_route('login')
    expect(page).to have_css('.auth-provider--github')
  end

  it 'does not redirect the admin password login link' do
    visit '/#login/admin/invalid-token'

    expect(page).to have_text('The token for the admin password login is invalid.')
  end

  it 'shows the login page right after a redirect' do
    Setting.set('third_party_login_auto_redirect', false)
    visit '/#login'
    execute_script("sessionStorage.setItem('third-party-login-auto-redirect-at', String(Date.now()))")

    Setting.set('third_party_login_auto_redirect', true)
    refresh

    expect(page).to have_current_route('login')

    expect(page).to have_css('.auth-provider--github')
  end

  context 'with password login enabled' do
    before { Setting.set('user_show_password_login', true) }

    it 'shows the login page' do
      visit '/'

      expect(page).to have_css('#login')
      expect(page).to have_css('.auth-provider--github')
    end
  end

  context 'with more than one provider' do
    before { Setting.set('auth_saml', true) }

    it 'shows the login page' do
      visit '/'

      expect(page).to have_css('.auth-provider--github')
      expect(page).to have_css('.auth-provider--saml')
    end
  end

  context 'when the setting is disabled' do
    before { Setting.set('third_party_login_auto_redirect', false) }

    it 'shows the login page' do
      visit '/'

      expect(page).to have_current_route('login')
      expect(page).to have_css('.auth-provider--github')
    end
  end

  context 'when an admin opens the security settings', authenticated_as: true do
    it 'shows the setting' do
      visit '/#settings/security'

      within :active_content do
        expect(page).to have_text('Automatic Third-party Login')
      end
    end
  end
end
