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
        assert_equal( action[:title], text  )
      end
      return
    elsif action[:execute] == 'verify_ticket_attributes'
      if action[:title]
        text = instance.find_elements( { :css => '.content.active .page-header .ticket-title-update' } )[0].text.strip
        assert_equal( action[:title], text  )
      end
      if action[:body]
        text = instance.find_elements( { :css => '.content.active [data-name="body"]' } )[0].text.strip
        assert_equal( action[:body], text  )
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
    elsif action[:execute] == 'create_ticket'
      instance.find_elements( { :css => 'a[href="#new"]' } )[0].click
      instance.find_elements( { :css => 'a[href="#ticket/create"]' } )[0].click
      element = instance.find_elements( { :css => '.active .newTicket' } )[0]
      if !element
        assert( false, "(#{test[:name]}) no ticket create screen found!" )
        return
      end
      sleep 2
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
      sleep 3
      element = instance.find_element( { :partial_link_text => action[:number] } ).click
      number = instance.find_elements( { :css => '.active .page-header .ticket-number' } )[0].text
      if number !~ /#{action[:number]}/
        assert( false, "(#{test[:name]}) unable to search/find ticket #{action[:number]}!" )
        return
      end
      assert( true, "(#{test[:name]}) ticket #{action[:number]} found" )
      return
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
