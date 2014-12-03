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
      if action[:remember_me]
        instance.find_element( { :css => '#login [name="remember_me"]' } ).click
      end
      instance.find_element( { :css => '#login button' } ).click
      sleep 4
      login = instance.find_element( { :css => '.user-menu .user a' } ).attribute('title')
      if login != action[:username]
        assert( false, "(#{test[:name]}) login failed" )
        return
      end
      assert( true, "(#{test[:name]}) login success" )
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
      timeout = 16
      if action[:timeout]
        timeout = action[:timeout]
      end
      loops = (timeout / 0.5).to_i
      text = ''
      (1..loops).each { |loop|
        begin
          element = instance.find_element( { :css => action[:area] } )
          if element && element.displayed?
            text = element.text
            if text =~ /#{action[:value]}/i
              assert( true, "(#{test[:name]}) '#{action[:value]}' found in '#{text}'" )
              sleep 0.4
              return
            end
          end
        rescue => e
          puts e.message
        end
        sleep 0.5
      }
      assert( false, "(#{test[:name]}) '#{action[:value]}' found in '#{text}'" )
      return
    elsif action[:execute] == 'watch_for_disappear'
      timeout = 16
      if action[:timeout]
        timeout = action[:timeout]
      end
      loops = (timeout / 0.5).to_i
      text = ''
      (1..loops).each { |loop|
        begin
          element = instance.find_element( { :css => action[:area] } )
          if !element || !element.displayed?
            assert( true, "(#{test[:name]}) not found" )
            sleep 0.4
            return
          end
        rescue => e
          #puts e.message
          assert( true, "(#{test[:name]}) not found" )
          sleep 0.4
          return
        end
        sleep 0.5
      }
      assert( false, "(#{test[:name]} / #{test[:area]}) still exsists" )
      return
    elsif action[:execute] == 'create_user'

      instance.find_element( { :css => 'a[href="#manage"]' } ).click
      instance.find_element( { :css => 'a[href="#manage/users"]' } ).click
      sleep 2
      instance.find_element( { :css => 'a[data-type="new"]' } ).click
      sleep 2
      #element = instance.find_element( { :css => '.modal input[name=login]' } )
      #element.clear
      #element.send_keys( action[:login] )
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
      instance.find_element( { :css => '.modal button.js-submit' } ).click
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

    elsif action[:execute] == 'verify_task_attributes'
      if action[:title]
        element = instance.find_element( { :css => '.tasks .active' } )
        assert_equal( action[:title], element.text.strip  )
      end
      return
    elsif action[:execute] == 'verify_ticket_attributes'
      if action[:title]
        element = instance.find_element( { :css => '.content.active .page-header .ticket-title-update' } )
        assert_equal( action[:title], element.text.strip  )
      end
      if action[:body]
        element = instance.find_element( { :css => '.content.active [data-name="body"]' } )
        assert_equal( action[:body], element.text.strip  )
      end
      return
    elsif action[:execute] == 'set_ticket_attributes'
      if action[:title]
        element = instance.find_element( { :css => '.content.active .page-header .ticket-title-update' } )
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
        element = instance.find_element( { :css => '.content.active [data-name="body"]' } )
        element.clear
        element.send_keys( action[:body] )
        # check if body is filled / in case use workaround
        body = element.text
        #puts "body '#{body}'"
        if !body || body.empty? || body == '' || body == ' '
          result = instance.execute_script( '$(".content.active [data-name=body]").text("' + action[:body] + '")' )
          #puts "r #{result.inspect}"
        end
      end
      return
    elsif action[:execute] == 'create_ticket'
      instance.find_element( { :css => 'a[href="#new"]' } ).click
      instance.find_element( { :css => 'a[href="#ticket/create"]' } ).click
      element = instance.find_element( { :css => '.active .newTicket' } )
      if !element
        assert( false, "(#{test[:name]}) no ticket create screen found!" )
        return
      end
      sleep 2
      if action[:customer] == nil
        element = instance.find_element( { :css => '.active .newTicket input[name="customer_id_completion"]' } )
        element.click
        element.clear

        # in certan cases focus is not set, do it this way
        instance.execute_script( '$(".content.active .newTicket input[name=customer_id_completion]").focus()' )
        element.send_keys( 'nico*' )
        sleep 4
        element.send_keys( :arrow_down )
        sleep 0.1
        instance.find_element( { :css => '.active .newTicket .recipientList-entry.js-user.is-active' } ).click
        sleep 0.3
      end
      if action[:group]
        element = instance.find_element( { :css => '.active .newTicket select[name="group_id"]' } )
        dropdown = Selenium::WebDriver::Support::Select.new(element)
        dropdown.select_by( :text, action[:group])
        sleep 0.2
      end
      if action[:subject]
        element = instance.find_element( { :css => '.active .newTicket input[name="title"]' } )
        element.clear
        element.send_keys( action[:subject] )
        sleep 0.2
      end
      if action[:body]
        element = instance.find_element( { :css => '.active .newTicket [data-name="body"]' } )
        element.clear
        element.send_keys( action[:body] )

        # check if body is filled / in case use workaround
        body = element.text
        #puts "body '#{body}'"
        if !body || body.empty? || body == '' || body == ' '
          result = instance.execute_script( '$(".content.active .newTicket [data-name=body]").text("' + action[:body] + '").focus()' )
          #puts "r #{result.inspect}"
        end
      end
      if action[:do_not_submit]
        assert( true, "(#{test[:name]}) ticket created without submit" )
        return
      end
      sleep 0.8
      #instance.execute_script( '$(".content.active .newTicket form").submit()' )
      instance.find_element( { :css => '.content.active .newTicket button.submit' } ).click
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
    elsif action[:execute] == 'close_all_tasks'
      for i in 1..100
        begin
          sleep 0.8
          hover_element = instance.find_element( { :css => '.navigation .tasks .task:first-child' } )
          if hover_element
            instance.mouse.move_to(hover_element)
            sleep 0.1
            click_element = instance.find_element( { :css => '.navigation .tasks .task:first-child .js-close' } )
            if click_element
              click_element.click
              sleep 0.2
            end
          else
            break
          end
        rescue => e
          puts e.message
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
    elsif action[:execute] == 'sendkey'
    else
      assert( false, "(#{test[:name]}) unknow action '#{action[:execute]}'" )
    end
  end
end
