# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > App Update Check', type: :system, app: :mobile do
  context 'when app is not configured yet', set_up: false, authenticated_as: false do
    before do
      visit '/mobile/login', skip_waiting: true
    end

    it 'redirects to desktop app for system set-up' do
      expect_current_route('getting_started', app: :desktop)
    end
  end

  context 'when checking application rebuild notification', authenticated_as: false do
    before do
      visit '/login?ApplicationRebuildCheckInterval=500'
      wait_for_test_flag('useApplicationBuildChecksumQuery.firstResult')
      wait_for_test_flag('useAppMaintenanceSubscription.subscribed')
    end

    # TODO: test only the most popular rebuild dialog message in selenium and move the other stuff to the frontend.
    it 'shows app rebuild dialog' do
      # Append a newline to the manifest file to trigger a reload notification.
      File.open(Rails.public_path.join('vite/manifest.json'), 'a') do |file|
        file.write("\n")
      end

      expect(page).to have_text('A newer version of the app is available. Please reload at your earliest.')
    end

    it 'reacts to app_version message' do
      AppVersion.set(true, AppVersion::MSG_APP_VERSION)
      expect(page).to have_text('A newer version of the app is available. Please reload at your earliest.')
    end

    it 'reacts to reload_auto message' do
      AppVersion.set(true, AppVersion::MSG_RESTART_AUTO)
      expect(page).to have_text('A newer version of the app is available. Please reload at your earliest.')
    end

    it 'reacts to reload_manual message' do
      AppVersion.set(true, AppVersion::MSG_RESTART_MANUAL)
      expect(page).to have_text('A newer version of the app is available. Please reload at your earliest.')
    end

    it 'reacts to config_updated message' do
      AppVersion.set(true, AppVersion::MSG_CONFIG_CHANGED)
      expect(page).to have_text('The configuration of Zammad has changed. Please reload at your earliest.')
    end
  end

  context 'when maintenance mode is activated', authenticated_as: :user do
    before do
      wait_for_test_flag('applicationLoaded.loaded')
      wait_for_test_flag('useConfigUpdatesSubscription.subscribed')

      Setting.set('maintenance_mode', true)
    end

    # TODO: check what we really need here, because of the frontend integration tests.
    context 'with admin user' do
      let(:user) { create(:admin) }

      it 'does not log out' do
        expect_current_route '/'
      end
    end
  end

  context 'when maintenance message is sent', authenticated_as: false do
    before do
      visit '/'
      wait_for_test_flag('applicationLoaded.loaded')
      wait_for_test_flag('usePushMessagesSubscription.subscribed')
    end

    it 'reacts to maintenance broadcast message' do
      Gql::ZammadSchema.subscriptions.trigger(
        Gql::Subscriptions::PushMessages.field_name,
        {},
        {
          title: 'Attention',
          text:  'Maintenance test message.',
        }
      )
      expect(page).to have_text('Attention: Maintenance test message.')
    end
  end
end
