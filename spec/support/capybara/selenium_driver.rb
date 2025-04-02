# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# This file registers the custom Zammad chrome and firefox drivers.
# The options check if a REMOTE_URL ENV is given and change the
# configurations accordingly.

Capybara.register_driver(:zammad_chrome) do |app|
  build_chrome_driver(app)
end

Capybara.register_driver(:zammad_chrome_mobile) do |app|
  # User agent for Chrome Beta on Pixel 7 (Android 13).
  build_chrome_driver(app, user_agent: 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Mobile Safari/537.36')
end

Capybara.register_driver(:zammad_firefox) do |app|
  build_firefox_driver(app)
end

Capybara.register_driver(:zammad_firefox_mobile) do |app|
  # User agent for Firefox on Pixel 7 (Android 13).
  build_firefox_driver(app, user_agent: 'Mozilla/5.0 (Android 13; Mobile; rv:109.0) Gecko/112.0 Firefox/112.0')
end

# `clear_local_storage` and `clear_session_storage` are deprecated in Selenium, but Capybara still uses them.
#   For now, we can ignore these warnings.
# https://github.com/teamcapybara/capybara/issues/2779
Selenium::WebDriver.logger.ignore(:clear_local_storage, :clear_session_storage)

private

def build_chrome_driver(app, user_agent: nil)

  # Turn on browser logs
  chrome_options = Selenium::WebDriver::Chrome::Options.new(
    logging_prefs:    {
      browser: 'ALL'
    },
    prefs:            {
      'intl.accept_languages'                                => 'en-US',
      'profile.default_content_setting_values.notifications' => 1, # ALLOW notifications
    },
    # Disable shared memory usage as it does not really provide a performance gain but cause resource limit issues in CI.
    #   https://peter.sh/experiments/chromium-command-line-switches/
    args:             %w[
      --enable-logging
      --v=1
      --disable-component-update
      --disable-dev-shm-usage
      --disable-features=OptimizationGuideModelDownloading,OptimizationHintsFetching,OptimizationTargetPrediction,OptimizationHints
      --disable-search-engine-choice-screen
      --no-first-run
    ],
    # Disable the "Chrome is being controlled by automated test software." info bar.
    exclude_switches: ['enable-automation'],
  )

  driver_args = {
    browser: :chrome,
    options: chrome_options
  }

  if ENV['REMOTE_URL'].present?
    driver_args[:browser] = :remote
    driver_args[:url]     = ENV['REMOTE_URL']
    driver_args[:http_client] = Selenium::WebDriver::Remote::Http::Default.new(
      open_timeout: 120,
      read_timeout: 120
    )
  end

  if ENV['BROWSER_HEADLESS'].present?
    driver_args[:options].add_argument '--headless=new' # native headless for v109+
  end

  if user_agent.present?
    driver_args[:options].add_argument "--user-agent=\"#{user_agent}\""
  end

  driver_args[:options].add_argument '--allow-insecure-localhost'
  driver_args[:options].add_argument '--ignore-certificate-errors'

  ENV['FAKE_SELENIUM_LOGIN_USER_ID'] = nil
  ENV['FAKE_SELENIUM_LOGIN_PENDING'] = nil

  Capybara::Selenium::Driver.new(app, **driver_args).tap do |driver|
    # Selenium 4 installs a default file_detector which finds wrong files/directories such as zammad/test.
    driver.browser.file_detector = nil if ENV['REMOTE_URL'].present?
  end
end

def build_firefox_driver(app, user_agent: nil)
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['intl.locale.matchOS']      = false
  profile['intl.accept_languages']    = 'en-US'
  profile['general.useragent.locale'] = 'en-US'
  profile['permissions.default.desktop-notification'] = 1 # ALLOW notifications

  driver_args = {
    browser: :firefox,
    options: Selenium::WebDriver::Firefox::Options.new(profile: profile),
  }

  if ENV['REMOTE_URL'].present?
    driver_args[:browser] = :remote
    driver_args[:url]     = ENV['REMOTE_URL']
    driver_args[:http_client] = Selenium::WebDriver::Remote::Http::Default.new(
      open_timeout: 120,
      read_timeout: 120
    )
  end

  if ENV['BROWSER_HEADLESS'].present?
    driver_args[:options].add_argument '-headless'
  end

  if user_agent.present?
    driver_args[:options].add_preference 'general.useragent.override', user_agent
  end

  ENV['FAKE_SELENIUM_LOGIN_USER_ID'] = nil
  ENV['FAKE_SELENIUM_LOGIN_PENDING'] = nil

  Capybara::Selenium::Driver.new(app, **driver_args).tap do |driver|
    # Selenium 4 installs a default file_detector which finds wrong files/directories such as zammad/test.
    driver.browser.file_detector = nil if ENV['REMOTE_URL'].present?
  end
end
