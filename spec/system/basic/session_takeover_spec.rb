# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Session takeover check', type: :system do
  context 'when use logout action' do
    let(:agent)    { create(:agent) }

    it 'check that all tabs have been logged out', authenticated_as: :agent do
      visit '/'

      # open new tab
      open_window_and_switch

      visit '/'

      # Go back and check for session takeover message
      switch_to_window_index(1)

      expect(page).to have_text('A new session was created with your account. This session will be stopped to prevent a conflict.')
    end
  end

  # Ported from test/browser/taskbar_session_test.rb: sessions of different
  #   users must not conflict with each other.
  context 'when different users are logged in' do
    let(:agent) { create(:agent, password: 'test') }
    let(:admin) { create(:admin, password: 'test') }

    it 'does not take over the session of another user', authenticated_as: :admin do
      visit '/'

      using_session(:second_browser) do
        login(username: agent.login, password: 'test')

        visit '/'

        expect(page).to have_no_text('A new session was created')
      end

      expect(page).to have_no_text('A new session was created')
    end
  end
end
