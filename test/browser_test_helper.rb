ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'selenium-webdriver'

class TestCase < Test::Unit::TestCase
  def browser
    ENV['BROWSER'] || 'firefox'
  end

  def browser_support_cookies
    if browser =~ /(internet_explorer|ie)/i
      return false
    end
    return true
  end

  def browser_url
    ENV['BROWSER_URL'] || 'http://localhost:3000'
  end

  def browser_instance
    if !@browsers
      @browsers = {}
    end
    if !ENV['REMOTE_URL'] || ENV['REMOTE_URL'].empty?
      local_browser = Selenium::WebDriver.for( browser.to_sym )
      browser_instance_preferences(local_browser)
      @browsers[local_browser.hash] = local_browser
      return local_browser
    end

    caps = Selenium::WebDriver::Remote::Capabilities.send( browser )
    if ENV['BROWSER_OS']
      caps.platform = ENV['BROWSER_OS']
    end
    if ENV['BROWSER_VERSION']
      caps.version  = ENV['BROWSER_VERSION']
    end
    local_browser = Selenium::WebDriver.for(
      :remote,
      :url                  => ENV['REMOTE_URL'],
      :desired_capabilities => caps,
    )
    browser_instance_preferences(local_browser)
    @browsers[local_browser.hash] = local_browser
    return local_browser
  end

  def browser_instance_close(local_browser)
    return if !@browsers[local_browser.hash]
    @browsers.delete( local_browser.hash )
    local_browser.quit
  end

  def browser_instance_preferences(local_browser)
    #local_browser.manage.window.resize_to(1024, 1024)
    if ENV['REMOTE_URL'] !~ /saucelabs/i
      if @browsers.size < 1
        local_browser.manage.window.move_to(0, 0)
      else
        local_browser.manage.window.move_to(1024, 0)
      end
    end
    local_browser.manage.timeouts.implicit_wait = 3 # seconds
  end

  def teardown
    return if !@browsers
    @browsers.each { |hash, local_browser|
      browser_instance_close(local_browser)
    }
  end

=begin

  username = login(
    :browser     => browser1,
    :username    => 'someuser',
    :password    => 'somepassword',
    :url         => 'some url', # optional
    :remember_me => true, # optional
  )

=end

  def login(params)
    instance = params[:browser] || @browser

    if params[:url]
      instance.get( params[:url] )
    end

    element = instance.find_elements( { :css => '#login input[name="username"]' } )[0]
    if !element
      raise "No login box found"
    end
    element.clear
    element.send_keys( params[:username] )

    element = instance.find_elements( { :css => '#login input[name="password"]' } )[0]
    element.clear
    element.send_keys( params[:password] )

    if params[:remember_me]
      instance.find_elements( { :css => '#login [name="remember_me"]' } )[0].click
    end
    instance.find_elements( { :css => '#login button' } )[0].click

    sleep 4
    login = instance.find_elements( { :css => '.user-menu .user a' } )[0].attribute('title')
    if login != params[:username]
      raise "login failed"
    end
    assert( true, "login ok" )
    login
  end

=begin

  logout(
    :browser => browser1
  )

=end

  def logout(params = {})
    instance = params[:browser] || @browser

    instance.find_elements( { :css => 'a[href="#current_user"]' } )[0].click
    sleep 0.1
    instance.find_elements( { :css => 'a[href="#logout"]' } )[0].click
    (1..6).each {|loop|
      login = instance.find_elements( { :css => '#login' } )[0]
      if login
        assert( true, "logout ok" )
        return
      end
    }
    raise "no login box found, seems logout was not successfully!"
  end

=begin

  location(
    :browser => browser1,
    :url     => 'http://someurl',
  )

=end

  def location(params)
    instance = params[:browser] || @browser
    instance.get( params[:url] )
  end

=begin

  location_check(
    :browser => browser1,
    :url     => 'http://someurl',
  )

=end

  def location_check(params)
    instance = params[:browser] || @browser
    if instance.current_url !~ /#{Regexp.quote(params[:url])}/
      raise "url #{instance.current_url} is not matching #{params[:url]}"
    end
    assert( true, "url #{instance.current_url} is matching #{params[:url]}" )
  end

=begin

  reload(
    :browser => browser1,
  )

=end

  def reload(params = {})
    instance = params[:browser] || @browser
    instance.navigate.refresh
  end

=begin

  click(
    :browser => browser1,
    :css     => '.some_class',
  )

=end

  def click(params)
    instance = params[:browser] || @browser
    instance.find_elements( { :css => params[:css] } )[0].click
    sleep 0.5
  end

=begin

  exists(
    :browser => browser1,
    :css     => '.some_class',
  )

=end

  def exists(params)
    instance = params[:browser] || @browser
    if !instance.find_elements( { :css => params[:css] } )[0]
      raise "#{params[:css]} dosn't exist, but should"
    end
    true
  end

=begin

  exists_not(
    :browser => browser1,
    :css     => '.some_class',
  )

=end

  def exists_not(params)
    instance = params[:browser] || @browser
    if instance.find_elements( { :css => params[:css] } )[0]
      raise "#{params[:css]} exists but should not"
    end
    true
  end

=begin

  set(
    :browser => browser1,
    :css     => '.some_class',
    :value   => true,
    :slow    => false,
    :clear   => true, # todo
  )

=end

  def set(params)
    instance = params[:browser] || @browser

    element = instance.find_elements( { :css => params[:css] } )[0]
    element.clear

    if !params[:slow]
      element.send_keys( params[:value] )
    else
      element.send_keys( '' )
      keys = params[:value].to_s.split('')
      keys.each {|key|
        instance.action.send_keys(key).perform
      }
    end
    sleep 0.5
  end

=begin

  select(
    :browser => browser1,
    :css     => '.some_class',
    :value   => 'Some Value',
  )

=end

  def select(params)
    instance = params[:browser] || @browser

    begin
      element  = instance.find_elements( { :css => params[:css] } )[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by(:text, params[:value])
    rescue
      # just try again
      element  = instance.find_elements( { :css => params[:css] } )[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by(:text, params[:value])
    end
  end

=begin

  check(
    :browser => browser1,
    :css     => '.some_class',
  )

=end

  def check(params)
    instance = params[:browser] || @browser

    element = instance.find_elements( { :css => params[:css] } )[0]
    checked = element.attribute('checked')
    if !checked
      element.click
    end
  end

=begin

  uncheck(
    :browser => browser1,
    :css     => '.some_class',
  )

=end

  def uncheck(params)
    instance = params[:browser] || @browser

    element = instance.find_elements( { :css => params[:css] } )[0]
    checked = element.attribute('checked')
    if checked
      element.click
    end
  end

=begin

  sendkey(
    :browser => browser1,
    :value   => :enter,
  )

=end

  def sendkey(params)
    instance = params[:browser] || @browser
    if params[:value].class == Array
      params[:value].each {|key|
        instance.action.send_keys(key).perform
      }
      return
    end
    instance.action.send_keys(params[:value]).perform
    sleep 0.5
  end

=begin

  match(
    :browser          => browser1,
    :css              => '#content .text-1',
    :value            => 'some test for browser and some other for browser',
    :attribute        => 'some_attribute', # match on attribute
    :should_not_match => true,
    :no_quote         => false, # use regex
  )

=end

  def match(params)
    instance = params[:browser] || @browser
    element = instance.find_elements( { :css => params[:css] } )[0]

    if params[:css] =~ /select/
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      success  = false
      if dropdown.selected_options
        dropdown.selected_options.each {|option|
          if option.text == params[:value]
            success = true
          end
        }
      end
      if params[:should_not_match]
        if success
          raise "should not match '#{params[:value]}' in select list, but is matching"
        end
        return true
      else
        if !success
          raise "not matching '#{params[:value]}' in select list"
        end
        return true
      end
    end

    # match on attribute
    if params[:attribute]
      text = element.attribute( params[:attribute] )
    elsif params[:css] =~ /(input|textarea)/i
      text = element.attribute('value')
    else
      text = element.text
    end
    match = false
    if params[:no_quote]
      #puts "aaaa #{text}/#{params[:value]}"
      if text =~ /#{params[:value]}/i
        match = $1 || true
      end
    else
      if text =~ /#{Regexp.quote(params[:value])}/i
        match = true
      end
    end
    if match
      if params[:should_not_match]
        raise "matching '#{params[:value]}' in content '#{text}' but should not!"
      end
    else
      if !params[:should_not_match]
        raise "not matching '#{params[:value]}' in content '#{text}' but should!"
      end
    end
    sleep 0.8
    return match
  end

=begin

  match_not(
    :browser          => browser1,
    :css              => '#content .text-1',
    :value            => 'some test for browser and some other for browser',
    :attribute        => 'some_attribute', # match on attribute
    :should_not_match => true,
    :no_quote         => false, # use regex
  )

=end

  def match_not(params)
    params[:should_not_match] = true
    match(params)
  end

=begin

  cookie(
    :browser => browser1,
    :name    => '^_zammad.+?',
    :value   => '.+?',
    :expires => nil,
  )

  cookie(
    :browser          => browser1,
    :name             => '^_zammad.+?',
    :should_not_exist => true,
  )

=end

  def cookie(params)
    instance = params[:browser] || @browser

    if !browser_support_cookies
      assert( true, "'#{params[:value]}' ups browser is not supporting reading cookies, go ahead")
      return true
    end

    cookies = instance.manage.all_cookies
    cookies.each {|cookie|
      #puts "CCC #{cookie.inspect}"
      # :name=>"_zammad_session_c25832f4de2", :value=>"adc31cd21615cb0a7ab269184ec8b76f", :path=>"/", :domain=>"localhost", :expires=>nil, :secure=>false}
      if cookie[:name] =~ /#{params[:name]}/i
        if params.has_key?( :value ) && cookie[:value].to_s =~ /#{params[:value]}/i
          assert( true, "matching value '#{params[:value]}' in cookie '#{cookie.to_s}'" )
        else
          raise "not matching value '#{params[:value]}' in cookie '#{cookie.to_s}'"
        end
        if params.has_key?( :expires ) && cookie[:expires].to_s =~ /#{params[:expires]}/i
          assert( true, "matching expires '#{params[:expires].inspect}' in cookie '#{cookie.to_s}'" )
        else
          raise "not matching expires '#{params[:expires]}' in cookie '#{cookie.to_s}'"
        end

        if params[:should_not_exist]
          raise "cookie with name '#{params[:name]}' should not exist, but exists '#{cookies.to_s}'"
        end
        return
      end
    }
    if params[:should_not_exist]
      assert( true, "cookie with name '#{params[:name]}' is not existing" )
      return
    end
    raise "not matching name '#{params[:name]}' in cookie '#{cookies.to_s}'"
  end

=begin

  watch_for(
    :browser   => browser1,
    :css       => true,
    :value     => 'some text',
    :attribute => 'some_attribute' # optional
    :timeout   => '16', # in sec, default 16
  )

=end

  def watch_for(params = {})
    instance = params[:browser] || @browser

    timeout = 16
    if params[:timeout]
      timeout = params[:timeout]
    end
    loops = (timeout).to_i
    text = ''
    (1..loops).each { |loop|
      element = instance.find_elements( { :css => params[:css] } )[0]
      if element #&& element.displayed?
        begin

          # match pn attribute
          if params[:attribute]
            text = element.attribute( params[:attribute] )
          elsif params[:css] =~ /(input|textarea)/i
            text = element.attribute('value')
          else
            text = element.text
          end
          if text =~ /#{params[:value]}/i
            assert( true, "'#{params[:value]}' found in '#{text}'" )
            sleep 0.5
            return true
          end
        rescue
          # just try again
        end
      end
      sleep 1
    }
    raise "'#{params[:value]}' found in '#{text}'"
  end

=begin

  watch_for_disappear(
    :browser => browser1,
    :css     => true,
    :timeout => '16', # in sec, default 16
  )

=end

  def watch_for_disappear(params = {})
    instance = params[:browser] || @browser

    timeout = 16
    if params[:timeout]
      timeout = params[:timeout]
    end
    loops = (timeout).to_i
    text = ''
    (1..loops).each { |loop|
      element = instance.find_elements( { :css => params[:css] } )[0]
      if !element #|| element.displayed?
        assert( true, "not found" )
        sleep 1
        return true
      end
      sleep 1
    }
    raise "#{params[:css]}) still exsists"
  end

=begin

  tasks_close_all(
    :browser         => browser1,
    :discard_changes => true,
  )

=end

  def tasks_close_all(params = {})
    instance = params[:browser] || @browser

    for i in 1..100
      sleep 1
      begin
        if instance.find_elements( { :css => '.navigation .tasks .task:first-child' } )[0]
          instance.mouse.move_to( instance.find_elements( { :css => '.navigation .tasks .task:first-child' } )[0] )
          sleep 0.2

          click_element = instance.find_elements( { :css => '.navigation .tasks .task:first-child .js-close' } )[0]
          if click_element
            sleep 0.1
            click_element.click

            # accept task close warning
            if params[:discard_changes]
              sleep 1
              instance.find_elements( { :css => '.modal button.js-submit' } )[0].click
            end
          end
        else
          break
        end
      rescue
        # just try again
      end
    end
    sleep 1
    assert( true, "all tasks closed" )
  end

=begin

  username = overview_create(
    :browser => browser1,
    :data    => {
      :name              => name,
      :link              => name,
      :role              => 'Agent',
      :prio              => 1000,
      'order::direction' => 'down',
    }
  )

=end

  def overview_create(params)
    instance = params[:browser] || @browser
    data     = params[:data]

    instance.find_elements( { :css => 'a[href="#manage"]' } )[0].click
    instance.find_elements( { :css => 'a[href="#manage/overviews"]' } )[0].click
    instance.find_elements( { :css => '#content a[data-type="new"]' } )[0].click
    sleep 2

    if data[:name]
      element = instance.find_elements( { :css => '.modal input[name=name]' } )[0]
      element.clear
      element.send_keys( data[:name] )
    end
    if data[:link]
      element = instance.find_elements( { :css => '.modal input[name=link]' } )[0]
      element.clear
      element.send_keys( data[:link] )
    end
    if data[:role]
      element = instance.find_elements( { :css => '.modal select[name="role_id"]' } )[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by( :text, data[:role])
    end
    if data[:prio]
      element = instance.find_elements( { :css => '.modal input[name=prio]' } )[0]
      element.clear
      element.send_keys( data[:prio] )
    end
    if data['order::direction']
      element = instance.find_elements( { :css => '.modal select[name="order::direction"]' } )[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by( :text, data['order::direction'])
    end

    instance.find_elements( { :css => '.modal button.js-submit' } )[0].click
    (1..12).each {|loop|
      element = instance.find_elements( { :css => 'body' } )[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert( true, "overview created" )
        overview = {
          :name => name,
        }
        return overview
      end
      sleep 1
    }
    raise "overview creation failed"
  end

=begin

  ticket = ticket_create(
    :browser => browser1,
    :data    => {
      :customer => 'nico',
      :group    => 'Users',
      :title    => 'overview #1',
      :body     => 'overview #1',
    },
    :do_not_submit => true,
  )

  returns (in case of submitted)
    {
      :id     => 123,
      :number => '100001',
    }

=end

  def ticket_create(params)
    instance = params[:browser] || @browser
    data     = params[:data]

    instance.find_elements( { :css => 'a[href="#new"]' } )[0].click
    instance.find_elements( { :css => 'a[href="#ticket/create"]' } )[0].click
    element = instance.find_elements( { :css => '.active .newTicket' } )[0]
    if !element
      raise "no ticket create screen found!"
    end
    sleep 1

    # check count of agents, should be only 1 / - selection on init screen
    count = instance.find_elements( { :css => '.active .newTicket select[name="owner_id"] option' } ).count
    assert_equal( 1, count, 'check if owner selection is empty per default'  )

    if data[:group]
      element = instance.find_elements( { :css => '.active .newTicket select[name="group_id"]' } )[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by( :text, data[:group])
      sleep 0.2
    end
    if data[:title]
      element = instance.find_elements( { :css => '.active .newTicket input[name="title"]' } )[0]
      element.clear
      element.send_keys( data[:title] )
      sleep 0.2
    end
    if data[:body]
      #instance.execute_script( '$(".active .newTicket div[data-name=body]").focus()' )
      sleep 0.5
      element = instance.find_elements( { :css => '.active .newTicket div[data-name=body]' } )[0]
      element.clear
      element.send_keys( data[:body] )
    end
    if data[:customer]
      element = instance.find_elements( { :css => '.active .newTicket input[name="customer_id_completion"]' } )[0]
      element.click
      element.clear
      element.send_keys( data[:customer] )
      sleep 4
      element.send_keys( :arrow_down )
      sleep 0.1
      instance.find_elements( { :css => '.active .newTicket .recipientList-entry.js-user.is-active' } )[0].click
      sleep 0.3
    end
    if params[:do_not_submit]
      assert( true, "ticket created without submit" )
      return
    end
    sleep 0.8
    #instance.execute_script( '$(".content.active .newTicket form").submit();' )
    instance.find_elements( { :css => '.active .newTicket button.submit' } )[0].click
    sleep 1
    (1..16).each {|loop|
      if instance.current_url =~ /#{Regexp.quote('#ticket/zoom/')}/
        assert( true, "ticket created" )
        sleep 0.5
        id = instance.current_url
        id.gsub!(//, )
        id.gsub!(/^.+?\/(\d+)$/, "\\1")

        number = instance.find_elements( { :css => '.active .page-header .ticket-number' } )[0].text
        ticket = {
          :id     => id,
          :number => number,
        }
        sleep 1
        return ticket
      end
      sleep 0.5
    }
    raise "ticket creation failed, can't get zoom url"
  end

=begin

  ticket_update(
    :browser => browser1,
    :data    => {
      :title => '',
      :body  => 'some body',
      :group => 'some group',
      :state => 'closed',
    },
    :do_not_submit => true,
  )

=end

  def ticket_update(params)
    instance = params[:browser] || @browser
    data     = params[:data]


    if data[:title]
      #element = instance.find_elements( { :css => '.content.active .page-header .ticket-title-update' } )[0]
      #element.clear
      #sleep 0.5
      #element = instance.find_elements( { :css => '.content.active .page-header .ticket-title-update' } )[0]
      #element.send_keys( data[:title] )
      #sleep 0.5
      #element.send_keys( :tab )

      instance.execute_script( '$(".content.active .page-header .ticket-title-update").focus()' )
      instance.execute_script( '$(".content.active .page-header .ticket-title-update").text("' + data[:title] + '")' )
      instance.execute_script( '$(".content.active .page-header .ticket-title-update").blur()' )
      instance.execute_script( '$(".content.active .page-header .ticket-title-update").trigger("blur")' )
#          {
#            :where        => :instance2,
#            :execute      => 'sendkey',
#            :css          => '.content.active .page-header .ticket-title-update',
#            :value        => 'TTT',
#          },
#          {
#            :where        => :instance2,
#            :execute      => 'sendkey',
#            :css          => '.content.active .page-header .ticket-title-update',
#            :value        => :tab,
#          },
    end
    if data[:body]
      #instance.execute_script( '$(".content.active div[data-name=body]").focus()' )
      sleep 0.5
      element = instance.find_elements( { :css => '.content.active div[data-name=body]' } )[0]
      element.clear
      element.send_keys( data[:body] )
    end

    if data[:group]
      element = instance.find_elements( { :css => '.active .sidebar select[name="group_id"]' } )[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by( :text, data[:group])
      sleep 0.2
    end

    if data[:state]
      element = instance.find_elements( { :css => '.active .sidebar select[name="state_id"]' } )[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by( :text, data[:state])
      sleep 0.2
    end

    found = nil
    (1..5).each {|loop|
      if !found
        begin
          text = instance.find_elements( { :css => '.content.active .js-reset' } )[0].text
          if text =~ /(Discard your unsaved changes.|Verwerfen der)/
            found = true
          end
        rescue
          # just try again
        end
        sleep 1
      end
    }
    if !found
      raise "no discard message found"
    end

    if params[:do_not_submit]
      assert( true, "(#{test[:name]}) ticket updated without submit" )
      return true
    end

    instance.find_elements( { :css => '.content.active button.js-submit' } )[0].click

    (1..10).each {|loop|
      begin
        text = instance.find_elements( { :css => '.content.active .js-reset' } )[0].text
        if !text || text.empty?
          return true
        end
      rescue
        # just try again
      end
      sleep 1
    }
    raise "unable to update ticket"
  end

=begin

  ticket_open_by_overview(
    :browser => browser2,
    :number  => ticket1[:number],
    :link    => '#ticket/view/' + name,
  )

=end

  def ticket_open_by_overview(params)
    instance = params[:browser] || @browser

    instance.find_elements( { :css => '#navigation li.overviews a' } )[0].click
    sleep 1
    instance.find_elements( { :css => ".content.active .sidebar a[href=\"#{params[:link]}\"]" } )[0].click
    sleep 1
    element = instance.find_elements( { :partial_link_text => params[:number] } )[0].click
    sleep 1
    number = instance.find_elements( { :css => '.active .page-header .ticket-number' } )[0].text
    if number !~ /#{params[:number]}/
      raise "unable to search/find ticket #{params[:number]}!"
    end
    assert( true, "ticket #{params[:number]} found" )
  end

=begin

  ticket_open_by_search(
    :browser => browser2,
    :number  => ticket1[:number],
  )

=end

  def ticket_open_by_search(params)
    instance = params[:browser] || @browser

    # search by number
    element = instance.find_elements( { :css => '#global-search' } )[0]
    element.click
    element.clear
    element.send_keys( params[:number] )
    sleep 3

    # empty search box by x
    instance.find_elements( { :css => '.search .empty-search' } )[0].click
    sleep 0.5
    text = instance.find_elements( { :css => '#global-search' } )[0].attribute('value')
    if !text
      raise "#global-search is not empty!"
    end

    # search by number again
    element = instance.find_elements( { :css => '#global-search' } )[0]
    element.click
    element.clear
    element.send_keys( params[:number] )
    sleep 1

    # open ticket
    element = instance.find_element( { :partial_link_text => params[:number] } ).click
    number = instance.find_elements( { :css => '.active .page-header .ticket-number' } )[0].text
    if number !~ /#{params[:number]}/
      raise "unable to search/find ticket #{params[:number]}!"
    end
  end

=begin

  overview_count = overview_counter(
    :browser => browser2,
  )

  returns
    {
      '#ticket/view/all_unassigned' => 42,
    }

=end

  def overview_counter(params = {})
    instance = params[:browser] || @browser

    instance.find_elements( { :css => '#navigation li.overviews a' } )[0].click
    sleep 2
    overviews = {}
    instance.find_elements( { :css => '.content.active .sidebar a[href]' } ).each {|element|
      url = element.attribute('href')
      url.gsub!(/(http|https):\/\/.+?\/(.+?)$/, "\\2")
      overviews[url] = 0
      #puts url.inspect
      #puts element.inspect
    }
    overviews.each {|url, value|
      count = instance.find_elements( { :css => ".content.active .sidebar a[href=\"#{url}\"] .badge" } )[0].text
      overviews[url] = count.to_i
    }
    overviews
  end

=begin

  organization_open_by_search(
    :browser => browser2,
    :value   => 'some value',
  )

=end

  def organization_open_by_search(params = {})
    instance = params[:browser] || @browser

    element = instance.find_elements( { :css => '#global-search' } )[0]

    element.click
    element.clear
    element.send_keys( params[:value] )
    sleep 3
    instance.find_elements( { :css => '.search .empty-search' } )[0].click
    sleep 0.5
    text = instance.find_elements( { :css => '#global-search' } )[0].attribute('value')
    if !text
      raise "#global-search is not empty!"
    end
    element = instance.find_elements( { :css => '#global-search' } )[0]
    element.click
    element.clear
    element.send_keys( params[:value] )
    sleep 2
    element = instance.find_element( { :partial_link_text => params[:value] } ).click
    name = instance.find_elements( { :css => '.active h1' } )[0].text
    if name !~ /#{params[:value]}/
      raise "unable to search/find org #{params[:value]}!"
      return
    end
    assert( true, "org #{params[:value]} found" )
    true
  end

=begin

  user_open_by_search(
    :browser => browser2,
    :value   => 'some value',
  )

=end

  def user_open_by_search(params = {})
    instance = params[:browser] || @browser

    element = instance.find_elements( { :css => '#global-search' } )[0]
    element.click
    element.clear
    element.send_keys( params[:value] )
    sleep 3
    element = instance.find_element( { :partial_link_text => params[:value] } ).click
    name = instance.find_elements( { :css => '.active h1' } )[0].text
    if name !~ /#{params[:value]}/
      raise "unable to search/find user #{params[:value]}!"
    end
    assert( true, "user #{params[:term]} found" )
    true
  end

=begin

  user_create(
    :browser => browser2,
    :data => {
      :login     => 'some login' + random,
      :firstname => 'Manage Firstname' + random,
      :lastname  => 'Manage Lastname' + random,
      :email     => user_email,
      :password  => 'some-pass',
    },
  )

=end

  def user_create(params = {})
    instance = params[:browser] || @browser
    data     = params[:data]

    instance.find_elements( { :css => 'a[href="#manage"]' } )[0].click
    instance.find_elements( { :css => 'a[href="#manage/users"]' } )[0].click
    sleep 2
    instance.find_elements( { :css => 'a[data-type="new"]' } )[0].click
    sleep 2
    element = instance.find_elements( { :css => '.modal input[name=firstname]' } )[0]
    element.clear
    element.send_keys( data[:firstname] )
    element = instance.find_elements( { :css => '.modal input[name=lastname]' } )[0]
    element.clear
    element.send_keys( data[:lastname] )
    element = instance.find_elements( { :css => '.modal input[name=email]' } )[0]
    element.clear
    element.send_keys( data[:email] )
    element = instance.find_elements( { :css => '.modal input[name=password]' } )[0]
    element.clear
    element.send_keys( data[:password] )
    element = instance.find_elements( { :css => '.modal input[name=password_confirm]' } )[0]
    element.clear
    element.send_keys( data[:password] )
    instance.find_elements( { :css => '.modal input[name="role_ids"][value="3"]' } )[0].click
    instance.find_elements( { :css => '.modal button.js-submit' } )[0].click

    sleep 2
    set(
      :browser => instance,
      :css     => '.content .js-search',
      :value   => data[:email],
    )
    watch_for(
      :browser => instance,
      :css     => 'body',
      :value   => data[:lastname],
    )

    assert( true, "user created" )
  end

=begin

  sla_create(
    :browser => browser2,
    :data => {
       :name                => 'some sla' + random,
       :first_response_time => 61
    },
  )

=end

  def sla_create(params = {})
    instance = params[:browser] || @browser
    data     = params[:data]

    instance.find_elements( { :css => 'a[href="#manage"]' } )[0].click
    instance.find_elements( { :css => 'a[href="#manage/slas"]' } )[0].click
    sleep 2
    instance.find_elements( { :css => 'a[data-type="new"]' } )[0].click
    sleep 2
    element = instance.find_elements( { :css => '.modal input[name=name]' } )[0]
    element.clear
    element.send_keys( data[:name] )
    element = instance.find_elements( { :css => '.modal input[name=first_response_time]' } )[0]
    element.clear
    element.send_keys( data[:first_response_time] )
    instance.find_elements( { :css => '.modal button.js-submit' } )[0].click
    (1..8).each {|loop|
      element = instance.find_elements( { :css => 'body' } )[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert( true, "sla created" )
        return true
      end
      sleep 1
    }
    raise "sla creation failed"
  end

=begin

  text_module_create(
    :browser => browser2,
    :data => {
      :name     => 'some sla' + random,
      :keywords => 'some keywords',
      :content  => 'some content',
    },
  )

=end

  def text_module_create(params = {})
    instance = params[:browser] || @browser
    data     = params[:data]

    instance.find_elements( { :css => 'a[href="#manage"]' } )[0].click
    instance.find_elements( { :css => 'a[href="#manage/text_modules"]' } )[0].click
    sleep 2
    instance.find_elements( { :css => 'a[data-type="new"]' } )[0].click
    sleep 2
    element = instance.find_elements( { :css => '.modal input[name=name]' } )[0]
    element.clear
    element.send_keys( data[:name] )
    element = instance.find_elements( { :css => '.modal input[name=keywords]' } )[0]
    element.clear
    element.send_keys( data[:keywords] )
    element = instance.find_elements( { :css => '.modal textarea[name=content]' } )[0]
    element.clear
    element.send_keys( data[:content] )
    instance.find_elements( { :css => '.modal button.js-submit' } )[0].click
    (1..8).each {|loop|
      element = instance.find_elements( { :css => 'body' } )[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert( true, "text module created" )
        return true
      end
      sleep 1
    }
    raise "text module creation failed"
  end

  # Add more helper methods to be used by all tests here...
  def browser_login(data)
    all_tests = [
      {
        :name     => 'login',
        :instance => data[:instance] || browser_instance,
        :url      => data[:url] || browser_url,
        :action   => [
          {
            :execute  => 'login',
            :username => data[:username] || 'nicole.braun@zammad.org',
            :password => data[:password] || 'test'
          },
        ],
      },
    ];
    return all_tests
  end

  def browser_signle_test_with_login(tests, login = {})
    all_tests = browser_login( login )
    all_tests = all_tests.concat( tests )
    browser_single_test(all_tests)
  end

  def browser_double_test(tests)
    instance1 = browser_single_test( browser_login({
      :instance => tests[0][:instance1],
      :username => tests[0][:instance1_username],
      :password => tests[0][:instance1_password],
      :url      => tests[0][:url],
    }), true )
    instance2 = browser_single_test( browser_login({
      :instance => tests[0][:instance2],
      :username => tests[0][:instance2_username],
      :password => tests[0][:instance2_password],
      :url      => tests[0][:url],
    }), true )
    tests.each { |test|
      if test[:action]
        test[:action].each { |action|

          # wait
          if action[:execute] == 'wait'
            sleep action[:value]
            next
          end

          # ignore no browser defined action
          next if !action[:where]

          # set current browser
          if action[:where] == :instance1
            instance = instance1
          else
            instance = instance2
          end
          browser_element_action(test, action, instance)
        }
      end
    }
    browser_instance_close(instance1)
    browser_instance_close(instance2)
  end

  def browser_single_test(tests, keep_connection = false)
    instance = nil
    @stack   = nil
    tests.each { |test|
      if test[:instance]
        instance = test[:instance]
      end
      if test[:url]
        instance.get( test[:url] )
      end
      if test[:action]
        test[:action].each { |action|
          if action[:execute] == 'wait'
            sleep action[:value]
            next
          end
          browser_element_action(test, action, instance)
        }
      end
    }
    if keep_connection
      return instance
    end
    browser_instance_close(instance)
  end

  def browser_element_action(test, action, instance)
    puts "NOTICE #{Time.now.to_s}: " + action.inspect
    if action[:execute] !~ /accept|dismiss/i
      #cookies = instance.manage.all_cookies
      #cookies.each {|cookie|
      #  puts "  COOKIE " + cookie.to_s
      #}
    end

    sleep 0.1
    if action[:css]
      if action[:css].match '###stack###'
        action[:css].gsub! '###stack###', @stack
      end
      begin
        if action[:range] == 'all'
          element = instance.find_elements( { :css => action[:css] } )
        else
          element = instance.find_element( { :css => action[:css] } )
        end
      rescue
        element = nil
      end
      if action[:result] == false
        assert( !element, "(#{test[:name]}) Element with css '#{action[:css]}' exists" )
      else
        assert( element, "(#{test[:name]}) Element with css '#{action[:css]}' doesn't exist" )
      end
    elsif action[:element] == :url
        if instance.current_url =~ /#{Regexp.quote(action[:result])}/
          assert( true, "(#{test[:name]}) url #{instance.current_url} is matching #{action[:result]}" )
        else
          assert( false, "(#{test[:name]}) url #{instance.current_url} is not matching #{action[:result]}" )
        end
    elsif action[:element] == :title
      title = instance.title
      if title =~ /#{action[:value]}/i
        assert( true, "(#{test[:name]}) matching '#{action[:value]}' in title '#{title}'" )
      else
        assert( false, "(#{test[:name]}) not matching '#{action[:value]}' in title '#{title}'" )
      end
      return
    elsif action[:element] == :alert
      element = instance.switch_to.alert
    elsif action[:execute] == 'login'
      element = instance.find_elements( { :css => '#login input[name="username"]' } )[0]
      if !element
        assert( false, "(#{test[:name]}) no login box found!" )
        return
      end
      element.clear
      element.send_keys( action[:username] )
      element = instance.find_elements( { :css => '#login input[name="password"]' } )[0]
      element.clear
      element.send_keys( action[:password] )
      if action[:remember_me]
        instance.find_elements( { :css => '#login [name="remember_me"]' } )[0].click
      end
      instance.find_elements( { :css => '#login button' } )[0].click
      sleep 4
      login = instance.find_elements( { :css => '.user-menu .user a' } )[0].attribute('title')
      if login != action[:username]
        assert( false, "(#{test[:name]}) login failed" )
        return
      end
      assert( true, "(#{test[:name]}) login success" )
      return
    elsif action[:execute] == 'logout'
      instance.find_elements( { :css => 'a[href="#current_user"]' } )[0].click
      sleep 0.1
      instance.find_elements( { :css => 'a[href="#logout"]' } )[0].click
      (1..6).each {|loop|
        login = instance.find_elements( { :css => '#login' } )[0]
        if login
          assert( true, "(#{test[:name]}) logout" )
          return
        end
      }
      assert( false, "(#{test[:name]}) no login box found!" )
      return
    elsif action[:execute] == 'watch_for'
      timeout = 16
      if action[:timeout]
        timeout = action[:timeout]
      end
      loops = (timeout).to_i
      text = ''
      (1..loops).each { |loop|
        element = instance.find_elements( { :css => action[:area] } )[0]
        if element #&& element.displayed?
          begin
            text = element.text
            if text =~ /#{action[:value]}/i
              assert( true, "(#{test[:name]}) '#{action[:value]}' found in '#{text}'" )
              return
            end
          rescue
            # just try again
          end
        end
        sleep 1
      }
      assert( false, "(#{test[:name]}) '#{action[:value]}' found in '#{text}'" )
      return
    elsif action[:execute] == 'watch_for_disappear'
      timeout = 16
      if action[:timeout]
        timeout = action[:timeout]
      end
      loops = (timeout / 2).to_i
      text = ''
      (1..loops).each { |loop|
        element = instance.find_elements( { :css => action[:area] } )[0]
        if !element #|| element.displayed?
          assert( true, "(#{test[:name]}) not found" )
          sleep 0.2
          return
        end
        sleep 2
      }
      assert( false, "(#{test[:name]} / #{test[:area]}) still exsists" )
      return

    # create user
    elsif action[:execute] == 'create_user'
      instance.find_elements( { :css => 'a[href="#manage"]' } )[0].click
      instance.find_elements( { :css => 'a[href="#manage/users"]' } )[0].click
      sleep 2
      instance.find_elements( { :css => 'a[data-type="new"]' } )[0].click
      sleep 2
      #element = instance.find_element( { :css => '.modal input[name=login]' } )
      #element.clear
      #element.send_keys( action[:login] )
      element = instance.find_elements( { :css => '.modal input[name=firstname]' } )[0]
      element.clear
      element.send_keys( action[:firstname] )
      element = instance.find_elements( { :css => '.modal input[name=lastname]' } )[0]
      element.clear
      element.send_keys( action[:lastname] )
      element = instance.find_elements( { :css => '.modal input[name=email]' } )[0]
      element.clear
      element.send_keys( action[:email] )
      element = instance.find_elements( { :css => '.modal input[name=password]' } )[0]
      element.clear
      element.send_keys( action[:password] )
      element = instance.find_elements( { :css => '.modal input[name=password_confirm]' } )[0]
      element.clear
      element.send_keys( action[:password] )
      instance.find_elements( { :css => '.modal input[name="role_ids"][value="3"]' } )[0].click
      instance.find_elements( { :css => '.modal button.js-submit' } )[0].click
      (1..14).each {|loop|
        element = instance.find_elements( { :css => 'body' } )[0]
        text = element.text
        if text =~ /#{Regexp.quote(action[:lastname])}/
          assert( true, "(#{test[:name]}) user created" )
          return
        end
        sleep 0.5
      }
      assert( true, "(#{test[:name]}) user creation failed" )
      return

    # create signature
    elsif action[:execute] == 'create_signature'
      instance.find_elements( { :css => 'a[href="#manage"]' } )[0].click
      instance.find_elements( { :css => 'a[href="#channels/email"]' } )[0].click
      instance.find_elements( { :css => 'a[href="#c-signature"]' } )[0].click
      sleep 8
      instance.find_elements( { :css => '#content #c-signature a[data-type="new"]' } )[0].click
      sleep 2
      element = instance.find_elements( { :css => '.modal input[name=name]' } )[0]
      element.clear
      element.send_keys( action[:name] )
      element = instance.find_elements( { :css => '.modal textarea[name=body]' } )[0]
      element.clear
      element.send_keys( action[:body] )
      instance.find_elements( { :css => '.modal button.js-submit' } )[0].click
      (1..12).each {|loop|
        element = instance.find_elements( { :css => 'body' } )[0]
        text = element.text
        if text =~ /#{Regexp.quote(action[:name])}/
          assert( true, "(#{test[:name]}) signature created" )
          return
        end
        sleep 1
      }
      assert( true, "(#{test[:name]}) signature creation failed" )
      return

    # create group
    elsif action[:execute] == 'create_group'
      instance.find_elements( { :css => 'a[href="#manage"]' } )[0].click
      instance.find_elements( { :css => 'a[href="#manage/groups"]' } )[0].click
      sleep 2
      instance.find_elements( { :css => 'a[data-type="new"]' } )[0].click
      sleep 2
      element = instance.find_elements( { :css => '.modal input[name=name]' } )[0]
      element.clear
      element.send_keys( action[:name] )
      element = instance.find_elements( { :css => '.modal select[name="email_address_id"]' } )[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by( :index, 1 )
      #dropdown.select_by( :text, action[:group])
      if action[:signature]
        element = instance.find_elements( { :css => '.modal select[name="signature_id"]' } )[0]
        dropdown = Selenium::WebDriver::Support::Select.new(element)
        dropdown.select_by( :text, action[:signature])
      end
      instance.find_elements( { :css => '.modal button.js-submit' } )[0].click
      (1..12).each {|loop|
        element = instance.find_elements( { :css => 'body' } )[0]
        text = element.text
        if text =~ /#{Regexp.quote(action[:name])}/
          assert( true, "(#{test[:name]}) group created" )

          # add member
          if action[:member]
            action[:member].each {|login|
              instance.find_elements( { :css => 'a[href="#manage"]' } )[0].click
              instance.find_elements( { :css => 'a[href="#manage/users"]' } )[0].click
              sleep 2
              element = instance.find_elements( { :css => '#content [name="search"]' } )[0]
              element.clear
              element.send_keys( login )
              sleep 2
              #instance.find_elements( { :css => '#content table [data-id]' } )[0].click
              instance.execute_script( '$("#content table [data-id] td").first().click()' )
              sleep 2
              #instance.find_elements( { :css => 'label:contains(" ' + action[:name] + '")' } )[0].click
              instance.execute_script( '$(\'label:contains(" ' + action[:name] + '")\').first().click()' )
              instance.find_elements( { :css => '.modal button.js-submit' } )[0].click
            }
          end
          return
        end
        sleep 1
      }
      assert( true, "(#{test[:name]}) group creation failed" )
      return

    elsif action[:execute] == 'verify_task_attributes'
      if action[:title]
        text = instance.find_elements( { :css => '.tasks .active' } )[0].text.strip
        assert_equal( action[:title], text )
      end
      return
    elsif action[:execute] == 'verify_ticket_attributes'
      if action[:title]
        text = instance.find_elements( { :css => '.content.active .page-header .ticket-title-update' } )[0].text.strip
        assert_equal( action[:title], text )
      end
      if action[:body]
        text = instance.find_elements( { :css => '.content.active [data-name="body"]' } )[0].text.strip
        assert_equal( action[:body], text )
      end
      return
    elsif action[:execute] == 'set_ticket_attributes'
      if action[:title]
        #element = instance.find_elements( { :css => '.content.active .page-header .ticket-title-update' } )[0]
        #element.clear
        #sleep 0.5
        #element = instance.find_elements( { :css => '.content.active .page-header .ticket-title-update' } )[0]
        #element.send_keys( action[:title] )
        #sleep 0.5
        #element.send_keys( :tab )

        instance.execute_script( '$(".content.active .page-header .ticket-title-update").focus()' )
        instance.execute_script( '$(".content.active .page-header .ticket-title-update").text("' + action[:title] + '")' )
        instance.execute_script( '$(".content.active .page-header .ticket-title-update").blur()' )
        instance.execute_script( '$(".content.active .page-header .ticket-title-update").trigger("blur")' )
#          {
#            :where        => :instance2,
#            :execute      => 'sendkey',
#            :css          => '.content.active .page-header .ticket-title-update',
#            :value        => 'TTT',
#          },
#          {
#            :where        => :instance2,
#            :execute      => 'sendkey',
#            :css          => '.content.active .page-header .ticket-title-update',
#            :value        => :tab,
#          },
      end
      if action[:body]
        #instance.execute_script( '$(".content.active div[data-name=body]").focus()' )
        sleep 0.5
        element = instance.find_elements( { :css => '.content.active div[data-name=body]' } )[0]
        element.clear
        element.send_keys( action[:body] )
      end
      return

    # create ticket
    elsif action[:execute] == 'create_ticket'
      instance.find_elements( { :css => 'a[href="#new"]' } )[0].click
      instance.find_elements( { :css => 'a[href="#ticket/create"]' } )[0].click
      element = instance.find_elements( { :css => '.active .newTicket' } )[0]
      if !element
        assert( false, "(#{test[:name]}) no ticket create screen found!" )
        return
      end
      sleep 2

      # check count of agents, should be only 1 / - selection on init screen
      count = instance.find_elements( { :css => '.active .newTicket select[name="owner_id"] option' } ).count
      assert_equal( 1, count, 'check if owner selection is empty per default'  )

      if action[:group]
        element = instance.find_elements( { :css => '.active .newTicket select[name="group_id"]' } )[0]
        dropdown = Selenium::WebDriver::Support::Select.new(element)
        dropdown.select_by( :text, action[:group])
        sleep 0.2
      end
      if action[:subject]
        element = instance.find_elements( { :css => '.active .newTicket input[name="title"]' } )[0]
        element.clear
        element.send_keys( action[:subject] )
        sleep 0.2
      end
      if action[:body]
        #instance.execute_script( '$(".active .newTicket div[data-name=body]").focus()' )
        sleep 0.5
        element = instance.find_elements( { :css => '.active .newTicket div[data-name=body]' } )[0]
        element.clear
        element.send_keys( action[:body] )
      end
      if action[:customer] == nil
        element = instance.find_elements( { :css => '.active .newTicket input[name="customer_id_completion"]' } )[0]
        element.click
        element.clear
        element.send_keys( 'nico*' )
        sleep 4
        element.send_keys( :arrow_down )
        sleep 0.1
        instance.find_elements( { :css => '.active .newTicket .recipientList-entry.js-user.is-active' } )[0].click
        sleep 0.3
      end
      if action[:do_not_submit]
        assert( true, "(#{test[:name]}) ticket created without submit" )
        return
      end
      sleep 0.8
      #instance.execute_script( '$(".content.active .newTicket form").submit();' )
      instance.find_elements( { :css => '.active .newTicket button.submit' } )[0].click
      sleep 1
      (1..16).each {|loop|
        if instance.current_url =~ /#{Regexp.quote('#ticket/zoom/')}/
          assert( true, "(#{test[:name]}) ticket created" )
          sleep 1
          return
        end
        sleep 0.5
      }
      assert( false, "(#{test[:name]}) ticket creation failed, can't get zoom url" )
      return

    # search ticket
    elsif action[:execute] == 'search_ticket'
      element = instance.find_elements( { :css => '#global-search' } )[0]
      element.click
      element.clear
      action[:number].gsub! '###stack###', @stack
      element.send_keys( action[:number] )
      sleep 3
      instance.find_elements( { :css => '.search .empty-search' } )[0].click
      sleep 0.5
      text = instance.find_elements( { :css => '#global-search' } )[0].attribute('value')
      if !text
        assert( false, "(#{test[:name]}) #global-search is not empty!" )
        return
      end
      element = instance.find_elements( { :css => '#global-search' } )[0]
      element.click
      element.clear
      action[:number].gsub! '###stack###', @stack
      element.send_keys( action[:number] )
      sleep 2
      element = instance.find_element( { :partial_link_text => action[:number] } ).click
      number = instance.find_elements( { :css => '.active .page-header .ticket-number' } )[0].text
      if number !~ /#{action[:number]}/
        assert( false, "(#{test[:name]}) unable to search/find ticket #{action[:number]}!" )
        return
      end
      assert( true, "(#{test[:name]}) ticket #{action[:number]} found" )
      return

    # close all tasks
    elsif action[:execute] == 'close_all_tasks'
      for i in 1..100
        sleep 1
        if instance.find_elements( { :css => '.navigation .tasks .task:first-child' } )[0]
          instance.mouse.move_to( instance.find_elements( { :css => '.navigation .tasks .task:first-child' } )[0] )
          sleep 0.2

          click_element = instance.find_elements( { :css => '.navigation .tasks .task:first-child .js-close' } )[0]
          if click_element
            sleep 0.1
            click_element.click

            # accept task close warning
            if action[:discard_changes]
              sleep 1
              instance.find_elements( { :css => '.modal button.js-submit' } )[0].click
            end
          end
        else
          break
        end
      end
      assert( true, "(#{test[:name]}) all tasks closed" )
      return
    elsif action[:execute] == 'navigate'
      instance.navigate.to( action[:to] )
      return
    elsif action[:execute] == 'reload'
      instance.navigate.refresh
      return
    elsif action[:execute] == 'js'
      result = instance.execute_script( action[:value] )
    elsif action[:execute] == 'sendkey'
      if action[:value].class == Array
        action[:value].each {|key|
          instance.action.send_keys(key).perform
        }
      else
      instance.action.send_keys(action[:value]).perform
      #instance.action.send_keys(:enter).perform
      end
#      element.send_keys( action[:value] )
    elsif action[:link]
      if action[:link].match '###stack###'
        action[:link].gsub! '###stack###', @stack
      end
      element = instance.find_element( { :partial_link_text => action[:link] } )
    else
      assert( false, "(#{test[:name]}) unknow selector for '#{action[:element]}'" )
    end
    if action[:execute] == 'setCheck'
      checked = element.attribute('checked')
      if !checked
        element.click
      end
    elsif action[:execute] == 'setUncheck'
      checked = element.attribute('checked')
      if checked
        element.click
      end
    elsif action[:execute] == 'set'
      element.clear
      if action[:value] == '###stack###'
        element.send_keys( @stack )
      else
        if !action[:slow]
          element.send_keys( action[:value] )
        else
          element.send_keys( '' )
          keys = action[:value].to_s.split('')
          keys.each {|key|
            instance.action.send_keys(key).perform
          }
        end
        sleep 0.3
      end
    elsif action[:execute] == 'select'
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by(:text, action[:value])
    elsif action[:execute] == 'click'
      if element.class == Array
        element.each {|item|
          item.click
        }
      else
        element.click
      end
    elsif action[:execute] == 'accept'
      element.accept
    elsif action[:execute] == 'dismiss'
      element.dismiss
    elsif action[:execute] == 'send_key'
      element.send_keys action[:value]
    elsif action[:execute] == 'match'
      if action[:css] =~ /select/
        dropdown = Selenium::WebDriver::Support::Select.new(element)
        success  = false
        if dropdown.selected_options
          dropdown.selected_options.each {|option|
            if option.text == action[:value]
              success = true
            end
          }
        end
        if action[:match_result]
          if success
            assert( true, "(#{test[:name]}) matching '#{action[:value]}' in select list" )
          else
            assert( false, "(#{test[:name]}) not matching '#{action[:value]}' in select list" )
          end
        else
          if success
            assert( false, "(#{test[:name]}) not matching '#{action[:value]}' in select list" )
          else
            assert( true, "(#{test[:name]}) matching '#{action[:value]}' in select list" )
          end
        end
      else
        if action[:attribute]
          text = element.attribute( action[:attribute] )
        elsif action[:css] =~ /(input|textarea)/i
          text = element.attribute('value')
        else
          text = element.text
        end
        if action[:value] == '###stack###'
          action[:value] = @stack
        end
        match = false
        if action[:no_quote]
          #puts "aaaa #{text}/#{action[:value]}"
          if text =~ /#{action[:value]}/i
            if $1
              @stack = $1
            end
            match = $1 || true
          end
        else
          if text =~ /#{Regexp.quote(action[:value])}/i
            match = true
          end
        end
        if match
          if action[:match_result]
            assert( true, "(#{test[:name]}) matching '#{action[:value]}' in content '#{text}'" )
          else
            assert( false, "(#{test[:name]}) matching '#{action[:value]}' in content '#{text}' but should not!" )
          end
        else
          if !action[:match_result]
            assert( true, "(#{test[:name]}) not matching '#{action[:value]}' in content '#{text}'" )
          else
            assert( false, "(#{test[:name]}) not matching '#{action[:value]}' in content '#{text}' but should not!" )
          end
        end
      end
    elsif action[:execute] == 'check'
    elsif action[:execute] == 'js'
    elsif action[:execute] == 'sendkey'
    else
      assert( false, "(#{test[:name]}) unknow action '#{action[:execute]}'" )
    end
  end
end
