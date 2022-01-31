# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > App Update Check', type: :system, authenticated_as: false do
  before do
    page.driver.browser.manage.window.resize_to(390, 844)
    visit '/mobile/login?ApplicationRebuildCheckInterval=1000'
    wait.until do
      page.evaluate_script('window.appVersionSubscriptionReady')
    end
  end

  it 'shows app rebuild dialog' do
    # Append a newline to the manifest file to trigger a reload notification.
    File.open(Rails.root.join('public/vite/manifest.json'), 'a') do |file|
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
