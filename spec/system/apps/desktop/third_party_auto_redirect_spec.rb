# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Automatic third-party login redirect', app: :desktop_view, authenticated_as: false, type: :system do
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
    visit "/tickets/#{ticket.id}"

    expect_current_route "/tickets/#{ticket.id}"
    expect(page).to have_text(ticket.title)
  end
end
