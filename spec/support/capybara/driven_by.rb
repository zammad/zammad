# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require_relative 'set_up'

RSpec.configure do |config|
  capybara_examples_performed = 0

  Capybara.register_server :puma_wrapper do |app, port, host, **_options|
    # Remember the dynamically assigned port.
    $capybara_port = port # rubocop:disable Style/GlobalVars
    # Start a silenced Puma as application server.
    Capybara.servers[:puma].call(app, port, host, Silent: true, Host: 'ssl://0.0.0.0', Threads: '0:16')
  end
  Capybara.server   = :puma_wrapper
  # See https://docs.gitlab.com/runner/executors/docker.html#create-a-network-for-each-job
  Capybara.app_host = ENV['CI'].present? ? 'https://build' : 'https://localhost'

  config.before(:each, type: :system) do |example|

    Setting.set('http_type', 'https')
    Setting.set('fqdn', ENV['CI'].present? ? "build:#{$capybara_port}" : "localhost:#{$capybara_port}") # rubocop:disable Style/GlobalVars

    browser_name = ENV.fetch('BROWSER', 'firefox')

    # If mobile user agent was requested by the example,
    #   use an appropriate driver (e.g. zammad_chrome_mobile).
    if example.metadata[:mobile_user_agent].present?
      browser_name += '_mobile'

      # End the Capybara browser session whenever the user agent is to be mocked,
      #   in order to get a fresh session for subsequent examples.
      Capybara.send(:session_pool).reverse_each do |_mode, session|
        session.quit
      end
    end

    # set custom Zammad driver (e.g. zammad_chrome) for special
    # functionalities and CI requirements
    driven_by(:"zammad_#{browser_name}")

    screen_size = example.metadata[:screen_size] || case example.metadata[:app]
                                                    when :mobile
                                                      :mobile
                                                    else
                                                      :desktop
                                                    end

    case screen_size
    when :mobile
      browser_width  = 390
      browser_height = 844
    when :tablet
      browser_width  = 1020
      browser_height = 760
    else # :desktop
      browser_width  = 1520
      browser_height = 1000
    end

    page.driver.browser.manage.window.resize_to(browser_width, browser_height)
  end

  config.after(:each, type: :system) do |example|
    capybara_examples_performed += 1
    # End the main capybara session only from time to time, to speed up tests and make
    #   sure memory consumption does not rise too much.
    # Also end the session whenever the user agent was mocked, in order to get a fresh
    #   session for subsequent examples.
    # Make sure additional sessions (from using_sessions) are always ended
    #   after every test and not kept alive. Selenium will automatically close
    #   idle sessions which can cause 404 errors later.
    #   (see https://github.com/teamcapybara/capybara/issues/2237)
    Capybara.send(:session_pool).reverse_each do |_mode, session|
      if !session.eql?(Capybara.current_session) || (capybara_examples_performed % 100).zero? || example.metadata[:mobile_user_agent]
        session.quit
      end
    end
  end

  retry_exceptions = [
    Net::OpenTimeout,
    Net::ReadTimeout,
    Selenium::WebDriver::Error::InvalidArgumentError,
    Selenium::WebDriver::Error::SessionNotCreatedError,
    Selenium::WebDriver::Error::UnknownError,
  ].freeze

  config.around(:each, type: :system) do |example|
    use_vcr = example.metadata.fetch(:use_vcr, false)

    # WebMock makes it impossible to have persistent http connections to Selenium,
    #    which may cause overhead and Net::OpenTimeout errors.
    WebMock.disable! if !use_vcr
    # rspec-retry
    example.run_with_retry retry: 3, exceptions_to_retry: retry_exceptions
    WebMock.enable! if !use_vcr
  end
end
