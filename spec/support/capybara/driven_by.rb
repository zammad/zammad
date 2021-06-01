# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_relative './set_up'

RSpec.configure do |config|
  config.before(:each, type: :system) do

    Capybara.register_server :puma_wrapper do |app, port, host, **_options|

      # update fqdn Setting according to random assigned Rack server port
      Setting.set('fqdn', "#{host}:#{port}")

      # start a silenced Puma as application server
      Capybara.servers[:puma].call(app, port, host, { Silent: true, Host: '0.0.0.0', Threads: '0:16' })
    end
    Capybara.server = :puma_wrapper

    # set the Host from gather container IP for CI runs
    if ENV['CI'].present?
      ip_address = Socket.ip_address_list.detect(&:ipv4_private?).ip_address
      host!("http://#{ip_address}")
    end

    # set custom Zammad driver (e.g. zammad_chrome) for special
    # functionalities and CI requirements
    driven_by(:"zammad_#{ENV.fetch('BROWSER', 'firefox')}")

    browser_width  = ENV['BROWSER_WIDTH'] || 1024
    browser_height = ENV['BROWSER_HEIGHT'] || 800
    page.driver.browser.manage.window.resize_to(browser_width, browser_height)
  end
end
