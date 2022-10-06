# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require_relative './set_up'

RSpec.configure do |config|
  capybara_examples_performed = 0

  config.before(:each, type: :system) do |example|

    Capybara.register_server :puma_wrapper do |app, port, host, **_options|

      # update fqdn Setting according to random assigned Rack server port
      Setting.set('fqdn', "#{host}:#{port}")

      # start a silenced Puma as application server
      Capybara.servers[:puma].call(app, port, host, Silent: true, Host: '0.0.0.0', Threads: '0:16')
    end
    Capybara.server = :puma_wrapper

    # set the Host from gather container IP for CI runs
    if ENV['CI'].present?
      ip_address = Socket.ip_address_list.detect(&:ipv4_private?).ip_address
      Capybara.app_host = "http://#{ip_address}"
    end

    if Capybara.app_host.nil?
      Capybara.app_host = 'http://localhost'
    end

    # set custom Zammad driver (e.g. zammad_chrome) for special
    # functionalities and CI requirements
    browser_name = ENV.fetch('BROWSER', 'firefox')
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

  config.after(:each, type: :system) do
    capybara_examples_performed += 1
    # End the main capybara session only from time to time, to speed up tests and make
    #   sure memory consumption does not rise too much.
    # Make sure additional sessions (from using_sessions) are always ended
    #   after every test and not kept alive. Selenium will automatically close
    #   idle sessions which can cause 404 errors later.
    #   (see https://github.com/teamcapybara/capybara/issues/2237)
    Capybara.send(:session_pool).reverse_each do |_mode, session|
      if !session.eql?(Capybara.current_session) || (capybara_examples_performed % 100).zero?
        session.quit
      end
    end
  end

  config.around(:each, type: :system) do |example|
    use_vcr = example.metadata.fetch(:use_vcr, false)

    # WebMock makes it impossible to have persistent http connections to Selenium,
    #    which may cause overhead and Net::OpenTimeout errors.
    WebMock.disable! if !use_vcr
    # rspec-retry
    example.run_with_retry retry: 3, exceptions_to_retry: [Net::OpenTimeout, Net::ReadTimeout, Selenium::WebDriver::Error::UnknownError]
    WebMock.enable! if !use_vcr
  end
end
