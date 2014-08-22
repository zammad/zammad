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
      @browsers = []
    end
    if !ENV['REMOTE_URL'] || ENV['REMOTE_URL'].empty?
      local_browser = Selenium::WebDriver.for( browser.to_sym )
      browser_instance_preferences(local_browser)
      @browsers.push local_browser
      return local_browser
    end

    caps = Selenium::WebDriver::Remote::Capabilities.send( browser )
    caps.platform = ENV['BROWSER_OS'] || 'Windows 2008'
    caps.version  = ENV['BROWSER_VERSION'] || '8'
    local_browser = Selenium::WebDriver.for(
      :remote,
      :url                  => ENV['REMOTE_URL'],
      :desired_capabilities => caps,
    )
    browser_instance_preferences(local_browser)
    @browsers.push local_browser
    return local_browser
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

    # only shut down browser type once on local webdriver tests
    # otherwise this error will happen "Errno::ECONNREFUSED: Connection refused - connect(2)"
    if !ENV['REMOTE_URL']
      shutdown = {}
      @browsers.each{ |local_browser|
        next if shutdown[ local_browser.browser ]
        shutdown[ local_browser.browser ] = true
        local_browser.quit
      }
    else
      @browsers.each{ |local_browser|
        local_browser.quit
      }
    end
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
          if action[:execute] == 'wait'
            sleep action[:value]
            next
          end
          next if !action[:where]
          if action[:where] == :instance1
            instance = instance1
          else
            instance = instance2
          end

          browser_element_action(test, action, instance)
        }
      end
    }
    instance1.close
    instance2.close
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
    instance.close
  end

  def browser_element_action(test, action, instance)
    puts "NOTICE #{Time.now.to_s}: " + action.inspect
    if action[:execute] !~ /accept|dismiss/i
      cookies = instance.manage.all_cookies
      cookies.each {|cookie|
        puts "  COOKIE " + cookie.to_s
      }
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
    elsif action[:element] == :cookie
      if !browser_support_cookies
        assert( true, "(#{test[:name]}) '#{action[:value]}' ups browser is not supporting reading cookies")
        return
      end
      cookies = instance.manage.all_cookies
      cookies.each {|cookie|
        if cookie.to_s =~ /#{action[:value]}/i
          assert( true, "(#{test[:name]}) matching '#{action[:value]}' in cookie '#{cookie.to_s}'" )
          return
        end
      }
      assert( false, "(#{test[:name]}) not matching '#{action[:value]}' in cookie '#{cookies.to_s}'" )
      return
    elsif action[:element] == :alert
      element = instance.switch_to.alert
    elsif action[:execute] == 'login'
      element = instance.find_element( { :css => '#login input[name="username"]' } )
      if !element
        assert( false, "(#{test[:name]}) no login box found!" )
        return
      end
      element.clear
      element.send_keys( action[:username] )
      element = instance.find_element( { :css => '#login input[name="password"]' } )
      element.clear
      element.send_keys( action[:password] )
      instance.find_element( { :css => '#login button' } ).click
      sleep 4
      return
    elsif action[:execute] == 'logout'
      instance.find_element( { :css => 'a[href="#current_user"]' } ).click
      sleep 0.1
      instance.find_element( { :css => 'a[href="#logout"]' } ).click
      (1..6).each {|loop|
        login = instance.find_element( { :css => '#login' } )
        if login
          assert( true, "(#{test[:name]}) logout" )
          return
        end
      }
      assert( false, "(#{test[:name]}) no login box found!" )
      return
    elsif action[:execute] == 'watch_for'
      text = ''
      (1..36).each { |loop|
        element = instance.find_element( { :css => action[:area] } )
        text = element.text
        if text =~ /#{action[:value]}/i
          assert( true, "(#{test[:name]}) '#{action[:value]}' found in '#{text}'" )
          return
        end
        sleep 0.33
      }
      assert( false, "(#{test[:name]}) '#{action[:value]}' found in '#{text}'" )
      return
    elsif action[:execute] == 'create_user'

      instance.find_element( { :css => 'a[href="#manage"]' } ).click
      instance.find_element( { :css => 'a[href="#manage/users"]' } ).click
      sleep 2
      instance.find_element( { :css => 'a[data-type="new"]' } ).click
      sleep 2
      element = instance.find_element( { :css => '.modal input[name=login]' } )
      element.clear
      element.send_keys( action[:login] )
      element = instance.find_element( { :css => '.modal input[name=firstname]' } )
      element.clear
      element.send_keys( action[:firstname] )
      element = instance.find_element( { :css => '.modal input[name=lastname]' } )
      element.clear
      element.send_keys( action[:lastname] )
      element = instance.find_element( { :css => '.modal input[name=email]' } )
      element.clear
      element.send_keys( action[:email] )
      element = instance.find_element( { :css => '.modal input[name=password]' } )
      element.clear
      element.send_keys( action[:password] )
      element = instance.find_element( { :css => '.modal input[name=password_confirm]' } )
      element.clear
      element.send_keys( action[:password] )
      instance.find_element( { :css => '.modal input[name="role_ids"][value="3"]' } ).click
      instance.find_element( { :css => '.modal button.submit' } ).click
      (1..14).each {|loop|
        element = instance.find_element( { :css => 'body' } )
        text = element.text
        if text =~ /#{Regexp.quote(action[:lastname])}/
          assert( true, "(#{test[:name]}) user created" )
          return
        end
        sleep 0.5
      }
      assert( true, "(#{test[:name]}) user creation failed" )
      return
    elsif action[:execute] == 'create_ticket'
      instance.find_element( { :css => 'a[href="#new"]' } ).click
      instance.find_element( { :css => 'a[href="#ticket/create/call_inbound"]' } ).click
      element = instance.find_element( { :css => '.active .ticket_create' } )
      if !element
        assert( false, "(#{test[:name]}) no ticket create screen found!" )
        return
      end
      sleep 2
      element = instance.find_element( { :css => '.active .ticket_create input[name="customer_id_autocompletion"]' } )
      element.clear
      element.send_keys( 'nico*' )
      sleep 4
      element = instance.find_element( { :css => '.active .ticket_create input[name="customer_id_autocompletion"]' } )
      element.send_keys( :arrow_down )
      sleep 0.2
      element = instance.find_element( { :css => '.active .ticket_create input[name="customer_id_autocompletion"]' } )
      element.send_keys( :tab )
      sleep 0.1
      element = instance.find_element( { :css => '.active .ticket_create select[name="group_id"]' } )
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by( :text, action[:group])
      sleep 0.1
      element = instance.find_element( { :css => '.active .ticket_create input[name="subject"]' } )
      element.clear
      element.send_keys( action[:subject] )
      sleep 0.1
      element = instance.find_element( { :css => '.active .ticket_create textarea[name="body"]' } )
      element.clear
      element.send_keys( action[:body] )
      if action[:do_not_submit]
        assert( true, "(#{test[:name]}) ticket created without submit" )
        return
      end
      sleep 0.5
      instance.find_element( { :css => '.active .form-actions button[type="submit"]' } ).click
      sleep 2
      (1..14).each {|loop|
        if instance.current_url =~ /#{Regexp.quote('#ticket/zoom/')}/
          assert( true, "(#{test[:name]}) ticket created" )
          return
        end
        sleep 0.5
      }
      assert( true, "(#{test[:name]}) ticket creation failed, can't get zoom url" )
      return
    elsif action[:execute] == 'close_all_tasks'
      for i in 1..100
        begin
          element = instance.find_element( { :css => '.taskbar [data-type="close"]' } )
          if element
            element.click
            sleep 0.8
          else
            break
          end
        rescue
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
        element.send_keys( action[:value] )
      end
    elsif action[:execute] == 'sendkey'
      element.send_keys( action[:value] )
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
        if action[:css] =~ /(input|textarea)/i
          text = element.attribute('value')
        else
          text = element.text
        end
        if action[:value] == '###stack###'
          action[:value] = @stack
        end
        match = false
        if action[:no_quote]
          if text =~ /#{action[:value]}/
            if $1
              @stack = $1
            end
            match = $1 || true
          end
        else
          if text =~ /#{Regexp.quote(action[:value])}/
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
    else
      assert( false, "(#{test[:name]}) unknow action '#{action[:execute]}'" )
    end
  end
end
