# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# This file registers the custom Zammad chrome and firefox drivers.
# The options check if a REMOTE_URL ENV is given and change the
# configurations accordingly.

Capybara.register_driver(:zammad_chrome) do |app|

  # Turn on browser logs
  chrome_options = Selenium::WebDriver::Chrome::Options.new(
    logging_prefs:    {
      browser: 'ALL'
    },
    prefs:            {
      'intl.accept_languages'                                => 'en-US',
      'profile.default_content_setting_values.notifications' => 1, # ALLOW notifications
    },
    args:             %w[--enable-logging --v=1],
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

  ENV['FAKE_SELENIUM_LOGIN_USER_ID'] = nil
  ENV['FAKE_SELENIUM_LOGIN_PENDING'] = nil

  Capybara::Selenium::Driver.new(app, **driver_args).tap do |driver|
    # Selenium 4 installs a default file_detector which finds wrong files/directories such as zammad/test.
    driver.browser.file_detector = nil if ENV['REMOTE_URL'].present?
  end
end

Capybara.register_driver(:zammad_firefox) do |app|

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

  ENV['FAKE_SELENIUM_LOGIN_USER_ID'] = nil
  ENV['FAKE_SELENIUM_LOGIN_PENDING'] = nil

  Capybara::Selenium::Driver.new(app, **driver_args).tap do |driver|
    # Selenium 4 installs a default file_detector which finds wrong files/directories such as zammad/test.
    driver.browser.file_detector = nil if ENV['REMOTE_URL'].present?
  end
end
