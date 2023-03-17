# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > App Update Check', app: :mobile, type: :system do
  context 'when app is not configured yet', authenticated_as: false, set_up: false do
    before do
      visit '/mobile/login', skip_waiting: true
    end

    it 'redirects to desktop app for system set-up' do
      expect_current_route('getting_started', app: :desktop)
    end
  end

  context 'when checking application rebuild notification', authenticated_as: false do
    before do
      visit '/login?ApplicationRebuildCheckInterval=500', skip_waiting: true
      wait_for_test_flag('useApplicationBuildChecksumQuery.firstResult')
      wait_for_test_flag('useAppMaintenanceSubscription.subscribed')
    end

    it 'shows app rebuild dialog' do
      # Append a newline to the manifest file to trigger a reload notification.
      Rails.public_path.join('vite/manifest.json').open('a') do |file|
        file.write("\n")
      end

      expect(page).to have_text('A newer version of the app is available. Please reload at your earliest.')
    end
  end

  context 'when maintenance mode is activated', authenticated_as: :user do
    before do
      visit '/', skip_waiting: true
      wait_for_test_flag('applicationLoaded.loaded')
      wait_for_test_flag('useConfigUpdatesSubscription.subscribed')

      Setting.set('maintenance_mode', true)
    end

    context 'with admin user' do
      let(:user) { create(:admin) }

      it 'does not log out' do
        expect_current_route '/'
      end
    end
  end

  context 'when maintenance message is sent', authenticated_as: false do
    before do
      visit '/', skip_waiting: true
      wait_for_test_flag('applicationLoaded.loaded')
      wait_for_test_flag('usePushMessagesSubscription.subscribed')
    end

    it 'reacts to maintenance broadcast message' do
      Gql::Subscriptions::PushMessages.trigger({ title: 'Attention', text: 'Maintenance test message.' })
      expect(page).to have_text('Attention: Maintenance test message.')
    end
  end
end
