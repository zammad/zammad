# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require_relative './set_up'

RSpec.configure do |config|
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
      host!("http://#{ip_address}")
    end

    # set custom Zammad driver (e.g. zammad_chrome) for special
    # functionalities and CI requirements
    browser_name = ENV.fetch('BROWSER', 'firefox')
    driven_by(:"zammad_#{browser_name}")

    case example.metadata.fetch(:screen_size, :desktop)
    when :tablet
      browser_width  = 1020
      browser_height = 760
    else # :desktop
      browser_width  = 1520
      browser_height = 1000
    end

    # Firefox and Chrome effective screen sizes are slightly different
    # accomodate that by reducing declared screen size on Firefox
    browser_height -= 44 if browser_name == 'firefox'

    page.driver.browser.manage.window.resize_to(browser_width, browser_height)
  end
end
