ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'selenium-webdriver'

class TestCase < Test::Unit::TestCase
  def browser_url
    ENV['BROWSER_URL'] || 'http://localhost:3000'
  end

  def browser_instance
    if !@browsers
      @browsers = []
    end
    if !ENV['REMOTE_URL']
      if !ENV['BROWSER']
        ENV['BROWSER'] = 'firefox'
      end
      browser = Selenium::WebDriver.for( ENV['BROWSER'].to_sym )
      @browsers.push browser
      return browser
    end

    caps = Selenium::WebDriver::Remote::Capabilities.send( ENV['BROWSER'] )
    caps.platform = ENV['BROWSER_OS'] || 'Windows 2008'
    caps.version  = ENV['BROWSER_VERSION'] || '8'
    browser = Selenium::WebDriver.for(
      :remote,
      :url                  => ENV['REMOTE_URL'],
      :desired_capabilities => caps,
    )
    @browsers.push browser
    return browser
  end

  def teardown
    return if !@browsers

    # only shut down browser type once
    # otherwise this error will happen "Errno::ECONNREFUSED: Connection refused - connect(2)"
    shutdown = {}
    @browsers.each{ |browser|
      next if shutdown[ browser.browser ]
      shutdown[ browser.browser ] = true
      browser.quit
    }
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
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'check',
            :css     => '#login',
            :result  => true,
          },
          {
            :execute => 'set',
            :css     => 'input[name="username"]',
            :value   => data[:username] || 'nicole.braun@zammad.org',
          },
          {
            :execute => 'set',
            :css     => 'input[name="password"]',
            :value   => data[:password] || 'test'
          },
          {
            :execute => 'click',
            :css     => '#login button',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'check',
            :css     => '#login',
            :result  => false,
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
#puts "NOTICE: " + action.inspect
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
        assert( true, "(#{test[:name]}) matching '#{action[:value]}' in title" )
      else
        assert( false, "(#{test[:name]}) not matching '#{action[:value]}' in title" )
      end
      return
    elsif action[:element] == :cookie
      cookies = instance.manage.all_cookies
      cookies.each {|cookie|
        if cookie.to_s =~ /#{action[:value]}/i
          assert( true, "(#{test[:name]}) matching '#{action[:value]}' in cookie" )
          return
        end
      }
      assert( false, "(#{test[:name]}) not matching '#{action[:value]}' in cookie" )
      return
    elsif action[:element] == :alert
      element = instance.switch_to.alert
    elsif action[:execute] == 'close_all_tasks'
      while true
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
    elsif action[:execute] == 'navigate'
      instance.navigate.to( action[:to] )
    elsif action[:execute] == 'reload'
      instance.navigate.refresh
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
    if action[:execute] == 'set'
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
    elsif action[:execute] == 'close_all_tasks'
    elsif action[:execute] == 'navigate'
    elsif action[:execute] == 'reload'
    elsif action[:execute] == 'js'
    else
      assert( false, "(#{test[:name]}) unknow action '#{action[:execute]}'" )
    end
  end
end
