ENV['RAILS_ENV'] = 'test'
# rubocop:disable HandleExceptions, ClassVars, NonLocalExitFromIterator
require File.expand_path('../../config/environment', __FILE__)
require 'selenium-webdriver'

class TestCase < Test::Unit::TestCase
  @@debug = true
  def browser
    ENV['BROWSER'] || 'firefox'
  end

  def profile
    browser_profile = nil
    if browser == 'firefox'
      browser_profile = Selenium::WebDriver::Firefox::Profile.new

      browser_profile['intl.locale.matchOS']      = false
      browser_profile['intl.accept_languages']    = 'en-US'
      browser_profile['general.useragent.locale'] = 'en-US'
    elsif browser == 'chrome'

      # profile are only working on remote selenium
      if ENV['REMOTE_URL']
        browser_profile = Selenium::WebDriver::Chrome::Profile.new
        browser_profile['intl.accept_languages'] = 'en'
      end
    end
    browser_profile
  end

  def browser_support_cookies
    if browser =~ /(internet_explorer|ie)/i
      return false
    end
    true
  end

  def browser_url
    ENV['BROWSER_URL'] || 'http://localhost:3000'
  end

  def browser_instance
    if !@browsers
      @browsers = {}
    end
    if !ENV['REMOTE_URL'] || ENV['REMOTE_URL'].empty?
      local_browser = Selenium::WebDriver.for(browser.to_sym, profile: profile)
      @browsers[local_browser.hash] = local_browser
      browser_instance_preferences(local_browser)
      return local_browser
    end

    caps = Selenium::WebDriver::Remote::Capabilities.send(browser)
    if ENV['BROWSER_OS']
      caps.platform = ENV['BROWSER_OS']
    end
    if ENV['BROWSER_VERSION']
      caps.version  = ENV['BROWSER_VERSION']
    end
    local_browser = Selenium::WebDriver.for(
      :remote,
      url: ENV['REMOTE_URL'],
      desired_capabilities: caps,
    )
    @browsers[local_browser.hash] = local_browser

    # avoid "Cannot read property 'get_Current' of undefined" issues
    begin
      browser_instance_preferences(local_browser)
    rescue
      # just try again
      sleep 10
      browser_instance_preferences(local_browser)
    end

    # upload files from remote dir
    local_browser.file_detector = lambda do |args|
      str = args.first.to_s
      str if File.file?(str)
    end

    local_browser
  end

  def browser_instance_close(local_browser)
    return if !@browsers[local_browser.hash]
    @browsers.delete(local_browser.hash)
    local_browser.quit
  end

  def browser_instance_preferences(local_browser)
    local_browser.manage.window.resize_to(1024, 800)
    if ENV['REMOTE_URL'] !~ /saucelabs|(grid|ci)\.(zammad\.org|znuny\.com)/i
      if @browsers.count == 1
        local_browser.manage.window.move_to(0, 0)
      else
        local_browser.manage.window.move_to(1024, 0)
      end
    end
    local_browser.manage.timeouts.implicit_wait = 3 # seconds
  end

  def teardown
    return if !@browsers
    @browsers.each { |_hash, local_browser|
      screenshot(browser: local_browser, comment: 'teardown')
      browser_instance_close(local_browser)
    }
  end

  def screenshot(params)
    instance = params[:browser] || @browser
    comment = params[:comment] || ''
    filename = "tmp/#{Time.zone.now.strftime('screenshot_%Y_%m_%d__%H_%M_%S')}_#{comment}_#{instance.hash}.png"
    log('screenshot', { filename: filename })
    instance.save_screenshot(filename)
  end

=begin

  username = login(
    browser:     browser1,
    username:    'someuser',
    password:    'somepassword',
    url:         'some url', # optional
    remember_me: true, # optional
    auto_wizard: false, # optional, in case of auto wizard, skip login
  )

=end

  def login(params)
    switch_window_focus(params)
    log('login', params)
    instance = params[:browser] || @browser

    if params[:url]
      instance.get(params[:url])
    end

    element = instance.find_elements({ css: '#login input[name="username"]' })[0]
    if !element

      if params[:auto_wizard]
        watch_for(
          browser: instance,
          css:     'body',
          value:   'auto wizard is enabled',
          timeout: 10,
        )
        location( url: "#{browser_url}/#getting_started/auto_wizard" )
        sleep 10
        login = instance.find_elements({ css: '.user-menu .user a' })[0].attribute('title')
        if login != params[:username]
          screenshot(browser: instance, comment: 'auto wizard login failed')
          fail 'auto wizard login failed'
        end
        assert(true, 'auto wizard login ok')
        return
      end
      screenshot(browser: instance, comment: 'login_failed')
      fail 'No login box found'
    end

    screenshot(browser: instance, comment: 'login')

    element.clear
    element.send_keys(params[:username])

    element = instance.find_elements({ css: '#login input[name="password"]' })[0]
    element.clear
    element.send_keys(params[:password])

    if params[:remember_me]
      instance.find_elements({ css: '#login .checkbox-replacement' })[0].click
    end
    instance.find_elements({ css: '#login button' })[0].click

    sleep 5
    login = instance.find_elements({ css: '.user-menu .user a' })[0].attribute('title')
    if login != params[:username]
      screenshot(browser: instance, comment: 'login_failed')
      fail 'login failed'
    end
    screenshot(browser: instance, comment: 'login_ok')
    assert(true, 'login ok')
    login
  end

=begin

  logout(
    browser: browser1
  )

=end

  def logout(params = {})
    switch_window_focus(params)
    log('logout', params)

    instance = params[:browser] || @browser

    instance.find_elements({ css: 'a[href="#current_user"]' })[0].click
    sleep 0.1
    instance.find_elements({ css: 'a[href="#logout"]' })[0].click
    (1..6).each {
      sleep 1
      login = instance.find_elements({ css: '#login' })[0]

      next if !login
      screenshot(browser: instance, comment: 'logout_ok')
      assert(true, 'logout ok')
      return
    }
    screenshot(browser: instance, comment: 'logout_failed')
    fail 'no login box found, seems logout was not successfully!'
  end

=begin

  location(
    browser: browser1,
    url:     'http://someurl',
  )

=end

  def location(params)
    switch_window_focus(params)
    log('location', params)

    instance = params[:browser] || @browser
    instance.get(params[:url])

    # check if reload was successfull
    if !instance.find_elements({ css: 'body' })[0] || instance.find_elements({ css: 'body' })[0].text =~ /unavailable or too busy/i
      instance.navigate.refresh
    end
    screenshot(browser: instance, comment: 'location')
  end

=begin

  location_check(
    browser: browser1,
    url:     'http://someurl',
  )

=end

  def location_check(params)
    switch_window_focus(params)
    log('location_check', params)

    instance = params[:browser] || @browser
    if instance.current_url !~ /#{Regexp.quote(params[:url])}/
      screenshot(browser: instance, comment: 'location_check_failed')
      fail "url #{instance.current_url} is not matching #{params[:url]}"
    end
    assert(true, "url #{instance.current_url} is matching #{params[:url]}")
  end

=begin

  reload(
    browser: browser1,
  )

=end

  def reload(params = {})
    switch_window_focus(params)
    log('reload', params)

    instance = params[:browser] || @browser
    screenshot(browser: instance, comment: 'reload_before')
    instance.navigate.refresh

    # check if reload was successfull
    if !instance.find_elements({ css: 'body' })[0] || instance.find_elements({ css: 'body' })[0].text =~ /unavailable or too busy/i
      instance.navigate.refresh
    end
    screenshot(browser: instance, comment: 'reload_after')
  end

=begin

  click(
    browser: browser1,
    css:  '.some_class',
    fast: false, # do not wait
    wait: 1, # wait 1 sec.
  )

  click(
    browser: browser1,
    text: '.partial_link_text',
    fast: false, # do not wait
    wait: 1, # wait 1 sec.
  )

=end

  def click(params)
    switch_window_focus(params)
    log('click', params)

    instance = params[:browser] || @browser
    if params[:css]

      element = instance.find_elements({ css: params[:css] })[0]
      #instance.mouse.move_to(element)
      #sleep 0.2
      element.click

      # trigger also focus on input/select and textarea fields
      #if params[:css] =~ /(input|select|textarea)/
      #  instance.execute_script("$('#{params[:css]}').trigger('focus')")
      #  sleep 0.2
      #end
    else
      instance.find_elements({ partial_link_text: params[:text] })[0].click
    end
    sleep 0.4 if !params[:fast]
    sleep params[:wait] if params[:wait]
  end

=begin

  scroll_to(
    browser:  browser1,
    position: 'top', # botton
    css:      '.some_class',
  )

=end

  def scroll_to(params)
    switch_window_focus(params)
    log('scroll_to', params)

    instance = params[:browser] || @browser

    position = 'true'
    if params[:position] == 'botton'
      position = 'false'
    end

    execute(
      browser:  instance,
      js:       "\$('#{params[:css]}').get(0).scrollIntoView(#{position})",
      mute_log: params[:mute_log]
    )
    sleep 0.2
  end

=begin

  execute(
    browser: browser1,
    js:      '.some_class',
  )

=end

  def execute(params)
    switch_window_focus(params)
    log('js', params)

    instance = params[:browser] || @browser
    if params[:js]
      return instance.execute_script(params[:js])
    end
    fail "Invalid execute params #{params.inspect}"
  end

=begin

  exists(
    browser: browser1,
    css: '.some_class',
  )

=end

  def exists(params)
    switch_window_focus(params)
    log('exists', params)

    instance = params[:browser] || @browser
    if !instance.find_elements({ css: params[:css] } )[0]
      screenshot(browser: instance, comment: 'exists_failed')
      fail "#{params[:css]} dosn't exist, but should"
    end
    true
  end

=begin

  exists_not(
    browser: browser1,
    css: '.some_class',
  )

=end

  def exists_not(params)
    switch_window_focus(params)
    log('exists_not', params)

    instance = params[:browser] || @browser
    if instance.find_elements({ css: params[:css] } )[0]
      screenshot(browser: instance, comment: 'exists_not_failed')
      fail "#{params[:css]} exists but should not"
    end
    true
  end

=begin

  set(
    browser:  browser1,
    css:      '.some_class',
    value:    true,
    slow:     false,
    blur:     true,
    clear:    true, # todo | default: true
    no_click: true,
  )

=end

  def set(params)
    switch_window_focus(params)
    log('set', params)

    instance = params[:browser] || @browser

    element = instance.find_elements({ css: params[:css] })[0]
    if !params[:no_click]
      element.click
    end
    element.clear

    if !params[:slow]
      element.send_keys(params[:value])
    else
      element.send_keys('')
      keys = params[:value].to_s.split('')
      keys.each {|key|
        instance.action.send_keys(key).perform
      }
    end

    if params[:blur]
      instance.execute_script("$('#{params[:css]}').blur()")
    end

    sleep 0.5
  end

=begin

  select(
    browser: browser1,
    css:     '.some_class',
    value:   'Some Value',
  )

=end

  def select(params)
    switch_window_focus(params)
    log('select', params)

    instance = params[:browser] || @browser

    begin
      element  = instance.find_elements({ css: params[:css] })[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by(:text, params[:value])
      puts "select - #{params.inspect}"
    rescue
      # just try again
      element  = instance.find_elements({ css: params[:css] })[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by(:text, params[:value])
      puts "select2 - #{params.inspect}"
    end
  end

=begin

  switch(
    browser: browser1,
    css:  '.some_class',
    type: 'on', # 'off'
  )

=end

  def switch(params)
    switch_window_focus(params)
    log('switch', params)

    instance = params[:browser] || @browser

    element = instance.find_elements({ css: "#{params[:css]} input[type=checkbox]" })[0]
    checked = element.attribute('checked')
    if !checked
      if params[:type] == 'on'
        instance.find_elements({ css: "#{params[:css]} label" })[0].click
      end
    elsif params[:type] == 'off'
      instance.find_elements({ css: "#{params[:css]} label" })[0].click
    end
  end

=begin

  check(
    browser: browser1,
    css:     '.some_class',
  )

=end

  def check(params)
    switch_window_focus(params)
    log('check', params)

    instance = params[:browser] || @browser

    element = instance.find_elements({ css: params[:css] })[0]
    checked = element.attribute('checked')
    element.click if !checked
  end

=begin

  uncheck(
    browser: browser1,
    css:     '.some_class',
  )

=end

  def uncheck(params)
    switch_window_focus(params)
    log('uncheck', params)

    instance = params[:browser] || @browser

    element = instance.find_elements({ css: params[:css] })[0]
    checked = element.attribute('checked')
    element.click if checked
  end

=begin

  sendkey(
    browser: browser1,
    value:   :enter,
    slow:    false,
  )

=end

  def sendkey(params)
    switch_window_focus(params)
    log('sendkey', params)

    instance = params[:browser] || @browser
    if params[:value].class == Array
      params[:value].each {|key|
        instance.action.send_keys(key).perform
      }
      return
    end
    instance.action.send_keys(params[:value]).perform
    if params[:slow]
      sleep 2
    else
      sleep 0.6
    end
  end

=begin

  match(
    browser: browser1,
    css: '#content .text-1',
    value: 'some test for browser and some other for browser',
    attribute: 'some_attribute', # match on attribute
    should_not_match: true,
    no_quote: false, # use regex
  )

=end

  def match(params, fallback = false)
    switch_window_focus(params)
    log('match', params)

    instance = params[:browser] || @browser
    element  = instance.find_elements({ css: params[:css] })[0]

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
          fail "should not match '#{params[:value]}' in select list, but is matching"
        end
      elsif !success
        fail "not matching '#{params[:value]}' in select list"
      end

      return true
    end

    # match on attribute
    begin
      text = if params[:attribute]
               element.attribute(params[:attribute])
             elsif params[:css] =~ /(input|textarea)/i
               element.attribute('value')
             else
               element.text
             end
    rescue => e

      # just try again
      if !fallback
        return match(params, true)
      end

      raise e.inspect
    end

    # do cleanups (needed for richtext tests)
    if params[:cleanup]
      text.gsub!(/\s+$/m, '')
      params[:value].gsub!(/\s+$/m, '')
    end

    match = false
    if params[:no_quote]
      #puts "aaaa #{text}/#{params[:value]}"
      if text =~ /#{params[:value]}/i
        match = $1 || true
      end
    elsif text =~ /#{Regexp.quote(params[:value])}/i
      match = true
    end

    if match
      if params[:should_not_match]
        fail "matching '#{params[:value]}' in content '#{text}' but should not!"
      end
    elsif !params[:should_not_match]
      fail "not matching '#{params[:value]}' in content '#{text}' but should!"
    end
    sleep 0.8
    match
  end

=begin

  match_not(
    browser: browser1,
    css: '#content .text-1',
    value: 'some test for browser and some other for browser',
    attribute: 'some_attribute', # match on attribute
    should_not_match: true,
    no_quote: false, # use regex
  )

=end

  def match_not(params)
    switch_window_focus(params)
    log('match_not', params)

    params[:should_not_match] = true
    match(params)
  end

=begin

  task_type(
    browser: browser1,
    type: 'stayOnTab',
  )

=end

  def task_type(params)
    switch_window_focus(params)
    log('task_type', params)

    instance = params[:browser] || @browser

    if params[:type]
      instance.find_elements({ css: '.content.active .js-secondaryActionButtonLabel' })[0].click
      instance.find_elements({ css: ".content.active .js-secondaryActionLabel[data-type=#{params[:type]}]" })[0].click
      return
    end
    fail "Unknown params for task_type: #{params.inspect}"
  end

=begin

  cookie(
    browser: browser1,
    name: '^_zammad.+?',
    value: '.+?',
    expires: nil,
  )

  cookie(
    browser: browser1,
    name: '^_zammad.+?',
    should_not_exist: true,
  )

=end

  def cookie(params)
    switch_window_focus(params)
    log('cookie', params)

    instance = params[:browser] || @browser

    if !browser_support_cookies
      assert(true, "'#{params[:value]}' ups browser is not supporting reading cookies, go ahead")
      return true
    end

    cookies = instance.manage.all_cookies
    cookies.each {|cookie|
      #puts "CCC #{cookie.inspect}"
      # :name=>"_zammad_session_c25832f4de2", :value=>"adc31cd21615cb0a7ab269184ec8b76f", :path=>"/", :domain=>"localhost", :expires=>nil, :secure=>false}
      next if cookie[:name] !~ /#{params[:name]}/i

      if params.key?(:value ) && cookie[:value].to_s =~ /#{params[:value]}/i
        assert(true, "matching value '#{params[:value]}' in cookie '#{cookie}'")
      else
        fail "not matching value '#{params[:value]}' in cookie '#{cookie}'"
      end
      if params.key?(:expires) && cookie[:expires].to_s =~ /#{params[:expires]}/i
        assert(true, "matching expires '#{params[:expires].inspect}' in cookie '#{cookie}'")
      else
        fail "not matching expires '#{params[:expires]}' in cookie '#{cookie}'"
      end

      return if !params[:should_not_exist]

      fail "cookie with name '#{params[:name]}' should not exist, but exists '#{cookies}'"
    }
    if params[:should_not_exist]
      assert(true, "cookie with name '#{params[:name]}' is not existing")
      return
    end
    fail "not matching name '#{params[:name]}' in cookie '#{cookies}'"
  end

=begin

  verify_title(
    browser: browser1,
    value: 'some title',
  )

=end

  def verify_title(params = {})
    switch_window_focus(params)
    log('verify_title', params)

    instance = params[:browser] || @browser

    title = instance.title
    if title =~ /#{params[:value]}/i
      assert(true, "matching '#{params[:value]}' in title '#{title}'")
    else
      fail "not matching '#{params[:value]}' in title '#{title}'"
    end
  end

=begin

  verify_task(
    browser: browser1,
    data: {
      title:    'some title',
      modified: true, # optional
    }
  )

=end

  def verify_task(params = {}, fallback = false)
    switch_window_focus(params)
    log('verify_task', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    sleep 1

    begin

      # verify title
      if data[:title]
        title = instance.find_elements({ css: '.tasks .is-active' })[0].text.strip
        if title =~ /#{data[:title]}/i
          assert(true, "matching '#{data[:title]}' in title '#{title}'")
        else
          fail "not matching '#{data[:title]}' in title '#{title}'"
        end
      end
      puts "tv #{params.inspect}"
      # verify modified
      if data.key?(:modified)
        exists      = instance.find_elements({ css: '.tasks .is-active' })[0]
        is_modified = instance.find_elements({ css: '.tasks .is-modified' })[0]
        puts "m #{data[:modified].inspect}"
        if exists
          puts ' exists'
        end
        if is_modified
          puts ' is_modified'
        end
        if data[:modified] == true
          if is_modified
            assert(true, "task '#{data[:title]}' is modifed")
          elsif !exists
            fail "task '#{data[:title]}' not exists, should not modified"
          else
            fail "task '#{data[:title]}' is not modifed"
          end
        elsif !is_modified
          assert(true, "task '#{data[:title]}' is modifed")
        elsif !exists
          fail "task '#{data[:title]}' not exists, should be not modified"
        else
          fail "task '#{data[:title]}' is modifed, but should not"
        end
      end
    rescue => e

      # just try again
      if !fallback
        verify_task(params, true)
      end
      raise 'ERROR: ' + e.inspect
    end
    true
  end

=begin

  open_task(
    browser: browser1,
    data: {
      title: 'some title',
    }
  )

=end

  def open_task(params = {}, _fallback = false)
    switch_window_focus(params)
    log('open_task', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    element = instance.find_elements({ partial_link_text: data[:title] })[0]
    if !element
      screenshot(browser: instance, comment: 'open_task_failed')
      fail "no task with title '#{data[:title]}' found"
    end
    element.click
    true
  end

=begin

  file_upload(
    browser: browser1,
    css:     '.active .attachmentPlaceholder-inputHolder input'
    files:   ['path/in/home/some_file.ext'], # 'test/fixtures/test1.pdf'
  )

=end

  def file_upload(params = {})
    switch_window_focus(params)
    log('file_upload', params)

    instance = params[:browser] || @browser

    params[:files].each {|file|
      instance.find_elements({ css: params[:css] })[0].send_keys "#{Rails.root}/#{file}"
    }
    sleep 2 * params[:files].count
  end

=begin

  watch_for(
    browser:   browser1,
    css:       '#content .text-1',
    value:     'some text',
    attribute: 'some_attribute' # optional
    timeout:   16, # in sec, default 16
  )

=end

  def watch_for(params = {})
    switch_window_focus(params)
    log('watch_for', params)

    instance = params[:browser] || @browser

    timeout = 16
    if params[:timeout]
      timeout = params[:timeout]
    end
    loops = timeout.to_i * 2
    text = ''
    (1..loops).each {
      element = instance.find_elements({ css: params[:css] })[0]
      if element #&& element.displayed?
        begin

          # match pn attribute
          text = if params[:attribute]
                   element.attribute(params[:attribute])
                 elsif params[:css] =~ /(input|textarea)/i
                   element.attribute('value')
                 else
                   element.text
                 end
          if text =~ /#{params[:value]}/i
            assert(true, "'#{params[:value]}' found in '#{text}'")
            sleep 0.5
            return true
          end
        rescue
          # try again
        end
      end
      sleep 0.5
    }
    screenshot(browser: instance, comment: 'watch_for_failed')
    fail "'#{params[:value]}' found in '#{text}'"
  end

=begin

wait untill selector disabppears

  watch_for_disappear(
    browser: browser1,
    css:     '#content .text-1',
    timeout: 16, # in sec, default 16
  )

wait untill text in selector disabppears

  watch_for_disappear(
    browser: browser1,
    css:     '#content .text-1',
    value:   'some value as regexp',
    timeout: 16, # in sec, default 16
  )

=end

  def watch_for_disappear(params = {})
    switch_window_focus(params)
    log('watch_for_disappear', params)

    instance = params[:browser] || @browser

    timeout = 16
    if params[:timeout]
      timeout = params[:timeout]
    end
    loops = timeout.to_i
    text  = ''
    (1..loops).each {
      element = instance.find_elements({ css: params[:css] })[0]
      if !element #|| element.displayed?
        assert(true, 'not found')
        sleep 1
        return true
      end
      if params[:value]
        begin
          text = instance.find_elements({ css: params[:css] })[0].text
          if text !~ /#{params[:value]}/i
            assert(true, "not matching '#{params[:value]}' in text '#{text}'")
            sleep 1
            return true
          end
        rescue
          # try again
        end
      end
      sleep 1
    }
    screenshot(browser: instance, comment: 'disappear_failed')
    fail "#{params[:css]}) still exsists"
  end

=begin

  tasks_close_all(
    browser: browser1,
    discard_changes: true,
  )

=end

  def tasks_close_all(params = {})
    switch_window_focus(params)
    log('tasks_close_all', params)

    instance = params[:browser] || @browser

    (1..100).each do
      sleep 1
      begin
        if instance.find_elements({ css: '.navigation .tasks .task:first-child' })[0]
          instance.mouse.move_to(instance.find_elements({ css: '.navigation .tasks .task:first-child' })[0])
          sleep 0.1
          click_element = instance.find_elements({ css: '.navigation .tasks .task:first-child .js-close' })[0]
          if click_element
            click_element.click

            # accept task close warning
            if params[:discard_changes]
              sleep 1
              instance.find_elements({ css: '.modal button.js-submit' })[0].click
            end
          end
        else
          break
        end
      rescue
        # try again
      end
    end
    sleep 1
    assert(true, 'all tasks closed')
  end

=begin

  ticket_customer_select(
    browser:  browser1,
    css:      '#content .text-1',
    customer: '',
  )

=end

  def ticket_customer_select(params = {})
    switch_window_focus(params)
    log('ticket_customer_select', params)

    instance = params[:browser] || @browser

    element = instance.find_elements({ css: params[:css] + ' input[name="customer_id_completion"]' })[0]
    element.click
    element.clear

    # workaround, sometimes focus is not triggered
    element.send_keys(params[:customer] + '*')
    sleep 3.5

    # check if pulldown is open, it's not working stable via selenium
    #instance.execute_script("$('#{params[:css]} .js-recipientDropdown').addClass('open')")
    #sleep 0.5
    element.send_keys(:arrow_down)
    sleep 0.3
    element.send_keys(:enter)
    #instance.find_elements({ css: params[:css] + ' .recipientList-entry.js-user.is-active' })[0].click
    sleep 0.6
    assert(true, 'ticket_customer_select')
  end

=begin

  username = overview_create(
    browser: browser1,
    data: {
      name:     name,
      role:     'Agent',
      selector: {
        'Priority': '1 low',
      },
      prio: 1000,
      'order::direction' => 'down',
    }
  )

=end

  def overview_create(params)
    switch_window_focus(params)
    log('overview_create', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    instance.find_elements({ css: 'a[href="#manage"]' })[0].click
    instance.find_elements({ css: 'a[href="#manage/overviews"]' })[0].click
    sleep 0.2
    instance.find_elements({ css: '#content a[data-type="new"]' })[0].click
    sleep 2

    if data[:name]
      element = instance.find_elements({ css: '.modal input[name=name]' })[0]
      element.clear
      element.send_keys(data[:name])
    end
    if data[:role]
      element = instance.find_elements({ css: '.modal select[name="role_id"]' })[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by(:text, data[:role])
    end

    if data[:selector]
      data[:selector].each {|key, value|
        element = instance.find_elements({ css: '.modal .ticket_selector .js-attributeSelector select' })[0]
        dropdown = Selenium::WebDriver::Support::Select.new(element)
        dropdown.select_by(:text, key)
        element = instance.find_elements({ css: '.modal .ticket_selector .js-value select' })[0]
        dropdown = Selenium::WebDriver::Support::Select.new(element)
        dropdown.deselect_all
        dropdown.select_by(:text, value)
      }
    end

    if data[:prio]
      element = instance.find_elements({ css: '.modal input[name=prio]' })[0]
      element.clear
      element.send_keys(data[:prio])
    end
    if data['order::direction']
      element = instance.find_elements({ css: '.modal select[name="order::direction"]' })[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by(:text, data['order::direction'])
    end

    instance.find_elements({ css: '.modal button.js-submit' })[0].click
    (1..12).each {
      element = instance.find_elements({ css: 'body' })[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert(true, 'overview created')
        overview = {
          name: name,
        }
        return overview
      end
      sleep 1
    }
    screenshot(browser: instance, comment: 'overview_create_failed')
    fail 'overview creation failed'
  end

=begin

  ticket = ticket_create(
    browser: browser1,
    data: {
      customer: 'nico',
      group:    'Users',
      priority: '2 normal',
      title:    'overview #1',
      body:     'overview #1',
    },
    do_not_submit: true,
  )

  returns (in case of submitted)
    {
      id:     123,
      number: '100001',
      title: 'overview #1',
    }

=end

  def ticket_create(params)
    switch_window_focus(params)
    log('ticket_create', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    instance.find_elements({ css: 'a[href="#new"]' })[0].click
    instance.find_elements({ css: 'a[href="#ticket/create"]' })[0].click
    element = instance.find_elements({ css: '.active .newTicket' })[0]
    if !element
      screenshot(browser: instance, comment: 'ticket_create_failed')
      fail 'no ticket create screen found!'
    end
    sleep 1

    # check count of agents, should be only 1 / - selection on init screen
    count = instance.find_elements({ css: '.active .newTicket select[name="owner_id"] option' }).count
    assert_equal(1, count, 'check if owner selection is empty per default' )

    if data[:group]
      element = instance.find_elements({ css: '.active .newTicket select[name="group_id"]' })[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by(:text, data[:group])
      sleep 0.2
    end
    if data[:priority]
      element = instance.find_elements({ css: '.active .newTicket select[name="priority_id"]' })[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by(:text, data[:priority])
      sleep 0.2
    end
    if data[:title]
      element = instance.find_elements({ css: '.active .newTicket input[name="title"]' })[0]
      element.clear
      element.send_keys(data[:title])
      sleep 0.2
    end
    if data[:body]
      #instance.execute_script('$(".active .newTicket div[data-name=body]").focus()')
      sleep 0.5
      element = instance.find_elements({ css: '.active .newTicket div[data-name=body]' })[0]
      element.clear
      element.send_keys(data[:body])

      # it's not working stable via selenium, use js
      value = instance.find_elements({ css: '.content .newTicket div[data-name=body]' })[0].text
      #puts "V #{value.inspect}"
      if value != data[:body]
        body_quoted = quote(data[:body])
        instance.execute_script("$('.content.active div[data-name=body]').html('#{body_quoted}').trigger('focusout')")
      end
    end
    if data[:customer]
      element = instance.find_elements({ css: '.active .newTicket input[name="customer_id_completion"]' })[0]
      element.click
      element.clear

      # workaround, sometimes focus is not triggered
      element.send_keys(data[:customer] + '*')
      sleep 3.5

      # check if pulldown is open, it's not working stable via selenium
      #instance.execute_script("$('.active .newTicket .js-recipientDropdown').addClass('open')")
      #sleep 0.5
      element.send_keys(:arrow_down)
      sleep 0.3
      element.send_keys(:enter)
      #instance.find_elements({ css: '.active .newTicket .recipientList-entry.js-user.is-active' })[0].click
      sleep 0.6
    end

    if data[:attachment]
      file_upload(
        browser: instance,
        css: '#content .text-1',
        value: 'some text',
      )
    end

    if params[:do_not_submit]
      assert(true, 'ticket created without submit')
      return
    end
    sleep 0.8
    #instance.execute_script('$(".content.active .newTicket form").submit();')
    instance.find_elements({ css: '.active .newTicket button.js-submit' })[0].click
    sleep 1
    (1..10).each {
      if instance.current_url =~ /#{Regexp.quote('#ticket/zoom/')}/
        assert(true, 'ticket created')
        sleep 2.5
        id = instance.current_url
        id.gsub!(//,)
        id.gsub!(%r{^.+?/(\d+)$}, '\\1')

        element = instance.find_elements({ css: '.active .ticketZoom-header .ticket-number' })[0]
        if element
          number = element.text
          ticket = {
            id: id,
            number: number,
            title: data[:title],
          }
          sleep 3 # wait until notify is gone
          screenshot(browser: instance, comment: 'ticket_create_ok')
          return ticket
        end
      end
      sleep 1
    }
    screenshot(browser: instance, comment: 'ticket_create_failed')
    fail "ticket creation failed, can't get zoom url (current url is '#{instance.current_url}')"
  end

=begin

  ticket_update(
    browser: browser1,
    data: {
      title:    '',
      customer: 'some_customer@example.com',
      body:     'some body',
      group:    'some group',
      priority: '1 low',
      state:    'closed',
    },
    do_not_submit: true,
  )

=end

  def ticket_update(params)
    switch_window_focus(params)
    log('ticket_update', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    if data[:title]
      #element = instance.find_elements({ :css => '.content.active .ticketZoom-header .ticket-title-update' })[0]
      #element.clear
      #sleep 0.5
      #element = instance.find_elements({ :css => '.content.active .ticketZoom-header .ticket-title-update' })[0]
      #element.send_keys(data[:title])
      #sleep 0.5
      #element.send_keys(:tab)

      instance.execute_script('$(".content.active .ticketZoom-header .ticket-title-update").focus()')
      instance.execute_script('$(".content.active .ticketZoom-header .ticket-title-update").text("' + data[:title] + '")')
      instance.execute_script('$(".content.active .ticketZoom-header .ticket-title-update").blur()')
      instance.execute_script('$(".content.active .ticketZoom-header .ticket-title-update").trigger("blur")')
      # {
      #   :where        => :instance2,
      #   :execute      => 'sendkey',
      #   :css          => '.content.active .ticketZoom-header .ticket-title-update',
      #   :value        => 'TTT',
      # },
      # {
      #   :where        => :instance2,
      #   :execute      => 'sendkey',
      #   :css          => '.content.active .ticketZoom-header .ticket-title-update',
      #   :value        => :tab,
      # },
    end
    if data[:customer]

      # select tab
      click(browser: instance, css: '.active .tabsSidebar-tab[data-tab="customer"]')

      click(browser: instance, css: '.active div[data-tab="customer"] .js-actions .icon-arrow-down')
      click(browser: instance, css: '.active div[data-tab="customer"] .js-actions [data-type="customer-change"]')
      watch_for(
        browser: instance,
        css: '.modal',
        value: 'change',
      )

      element = instance.find_elements({ css: '.modal input[name="customer_id_completion"]' })[0]
      element.click
      element.clear

      # workaround, sometimes focus is not triggered
      element.send_keys(data[:customer])
      sleep 3.5

      # check if pulldown is open, it's not working stable via selenium
      #instance.execute_script("$('.modal .user_autocompletion .js-recipientDropdown').addClass('open')")
      #sleep 0.5
      element.send_keys(:arrow_down)
      sleep 0.6
      element.send_keys(:enter)
      #instance.find_elements({ css: '.modal .user_autocompletion .recipientList-entry.js-user.is-active' })[0].click
      sleep 0.3

      click(browser: instance, css: '.modal .js-submit')

      watch_for_disappear(
        browser: instance,
        css: '.modal',
      )

      watch_for(
        browser: instance,
        css: '.active .tabsSidebar',
        value: data[:customer],
      )

      # select tab
      click(browser: instance, css: '.active .tabsSidebar-tab[data-tab="ticket"]')

    end
    if data[:body]
      #instance.execute_script('$(".content.active div[data-name=body]").focus()')
      sleep 0.5
      element = instance.find_elements({ css: '.content.active div[data-name=body]' })[0]
      element.clear
      element.send_keys(data[:body])

      # it's not working stable via selenium, use js
      value = instance.find_elements({ css: '.content.active div[data-name=body]' })[0].text
      if value != data[:body]
        body_quoted = quote(data[:body])
        instance.execute_script("$('.content.active div[data-name=body]').html('#{body_quoted}').trigger('focusout')")
      end

    end

    if data[:group]
      element = instance.find_elements({ css: '.active .sidebar select[name="group_id"]' })[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by(:text, data[:group])
      sleep 0.2
    end

    if data[:priority]
      element = instance.find_elements({ css: '.active .sidebar select[name="priority_id"]' })[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by(:text, data[:priority])
      sleep 0.2
    end

    if data[:state]
      element = instance.find_elements({ css: '.active .sidebar select[name="state_id"]' })[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by(:text, data[:state])
      sleep 0.2
    end

    if data[:state] || data[:group] || data[:body]
      found = nil
      (1..10).each {

        break if found

        begin
          text = instance.find_elements({ css: '.content.active .js-reset' })[0].text
          if text =~ /(Discard your unsaved changes.|Verwerfen der)/
            found = true
          end
        rescue
          # try again
        end
        sleep 1
      }
      if !found
        screenshot(browser: instance, comment: 'ticket_update_discard_message_failed')

        fail 'no discard message found'
      end
    end

    task_type(
      browser: instance,
      type:    'stayOnTab',
    )

    if params[:do_not_submit]
      assert(true, 'ticket updated without submit')
      return true
    end

    instance.find_elements({ css: '.content.active .js-submit' })[0].click

    (1..10).each {
      begin
        text = instance.find_elements({ css: '.content.active .js-reset' })[0].text
        if !text || text.empty?
          screenshot(browser: instance, comment: 'ticket_update_ok')
          return true
        end
      rescue
        # try again
      end
      sleep 1
    }
    screenshot(browser: instance, comment: 'ticket_update_failed')
    fail 'unable to update ticket'
  end

=begin

  ticket_verify(
    browser: browser1,
    data: {
      title: 'some title',
      body:  'some body',
##      group: 'some group',
##      state: 'closed',
    },
  )

=end

  def ticket_verify(params)
    switch_window_focus(params)
    log('ticket_verify', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    if data[:title]
      title = instance.find_elements({ css: '.content.active .ticketZoom-header .ticket-title-update' })[0].text.strip
      if title =~ /#{data[:title]}/i
        assert(true, "matching '#{data[:title]}' in title '#{title}'")
      else
        fail "not matching '#{data[:title]}' in title '#{title}'"
      end
    end

    if data[:body]
      body = instance.find_elements({ css: '.content.active [data-name="body"]' })[0].text.strip
      if body =~ /#{data[:body]}/i
        assert(true, "matching '#{data[:body]}' in body '#{body}'")
      else
        fail "not matching '#{data[:body]}' in body '#{body}'"
      end
    end
    true
  end

=begin

  ticket_open_by_overview(
    browser: browser2,
    number:  ticket1[:number],
    link:    "#ticket/view/#{name}",
  )

=end

  def ticket_open_by_overview(params)
    switch_window_focus(params)
    log('ticket_open_by_overview', params)

    instance = params[:browser] || @browser

    instance.find_elements({ css: '.js-overviewsMenuItem' })[0].click
    sleep 1
    execute(
      browser: instance,
      js: '$(".content.active .sidebar").css("display", "block")',
    )
    instance.find_elements({ css: ".content.active .sidebar a[href=\"#{params[:link]}\"]" })[0].click
    sleep 1
    execute(
      browser: instance,
      js: '$(".content.active .sidebar").css("display", "none")',
    )
    instance.find_elements({ partial_link_text: params[:number] })[0].click
    sleep 1
    number = instance.find_elements({ css: '.active .ticketZoom-header .ticket-number' })[0].text
    if number !~ /#{params[:number]}/
      screenshot(browser: instance, comment: 'ticket_open_by_overview_failed')
      fail "unable to search/find ticket #{params[:number]}!"
    end
    sleep 1
    assert(true, "ticket #{params[:number]} found")
    true
  end

=begin

  ticket_open_by_search(
    browser: browser2,
    number:  ticket1[:number],
  )

=end

  def ticket_open_by_search(params)
    switch_window_focus(params)
    log('ticket_open_by_search', params)

    instance = params[:browser] || @browser

    # search by number
    element = instance.find_elements({ css: '#global-search' })[0]
    element.click
    element.clear
    element.send_keys(params[:number])
    sleep 3

    # empty search box by x
    instance.find_elements({ css: '.search .empty-search' })[0].click
    sleep 0.5
    text = instance.find_elements({ css: '#global-search' })[0].attribute('value')
    if !text
      fail '#global-search is not empty!'
    end

    # search by number again
    element = instance.find_elements({ css: '#global-search' })[0]
    element.click
    element.clear
    element.send_keys(params[:number])
    sleep 1

    # open ticket
    #instance.find_element({ partial_link_text: params[:number] } ).click
    instance.execute_script("$(\"#global-search-result a:contains('#{params[:value]}') .nav-tab-icon\").click()")
    number = instance.find_elements({ css: '.active .ticketZoom-header .ticket-number' })[0].text
    if number !~ /#{params[:number]}/
      screenshot(browser: instance, comment: 'ticket_open_by_search_failed')
      fail "unable to search/find ticket #{params[:number]}!"
    end
    sleep 1
    true
  end

=begin

  ticket_open_by_title(
    browser: browser2,
    title:   ticket1[:title],
  )

=end

  def ticket_open_by_title(params)
    switch_window_focus(params)
    log('ticket_open_by_title', params)

    instance = params[:browser] || @browser

    # search by number
    element = instance.find_elements({ css: '#global-search' })[0]
    element.click
    element.clear
    element.send_keys(params[:title])
    sleep 3

    # open ticket
    #instance.find_element({ partial_link_text: params[:title] } ).click
    instance.execute_script("$(\"#global-search-result a:contains('#{params[:title]}') .nav-tab-icon\").click()")
    title = instance.find_elements({ css: '.active .ticketZoom-header .ticket-title-update' })[0].text
    if title !~ /#{params[:title]}/
      screenshot(browser: instance, comment: 'ticket_open_by_title_failed')
      fail "unable to search/find ticket #{params[:title]}!"
    end
    sleep 1
    true
  end

=begin

  overview_count = overview_counter(
    browser: browser2,
  )

  returns
    {
      '#ticket/view/all_unassigned' => 42,
    }

=end

  def overview_counter(params = {})
    switch_window_focus(params)
    log('overview_counter', params)

    instance = params[:browser] || @browser

    instance.find_elements({ css: '.js-overviewsMenuItem' })[0].click
    sleep 2

    execute(
      browser: instance,
      js: '$(".content.active .sidebar").css("display", "block")',
    )
    #execute(
    #  browser: instance,
    #  js: '$(".content.active .overview-header").css("display", "none")',
    #)

    overviews = {}
    instance.find_elements({ css: '.content.active .sidebar a[href]' }).each {|element|
      url = element.attribute('href')
      url.gsub!(%r{(http|https)://.+?/(.+?)$}, '\\2')
      overviews[url] = 0
      #puts url.inspect
      #puts element.inspect
    }
    overviews.each {|url, _value|
      count          = instance.find_elements({ css: ".content.active .sidebar a[href=\"#{url}\"] .badge" })[0].text
      overviews[url] = count.to_i
    }
    log('overview_counter', overviews)
    overviews
  end

=begin

  organization_open_by_search(
    browser: browser2,
    value:   'some value',
  )

=end

  def organization_open_by_search(params = {})
    switch_window_focus(params)
    log('organization_open_by_search', params)

    instance = params[:browser] || @browser

    element = instance.find_elements({ css: '#global-search' })[0]

    element.click
    element.clear
    element.send_keys(params[:value])
    sleep 3
    instance.find_elements({ css: '.search .empty-search' })[0].click
    sleep 0.5
    text = instance.find_elements({ css: '#global-search' })[0].attribute('value')
    if !text
      fail '#global-search is not empty!'
    end
    element = instance.find_elements({ css: '#global-search' })[0]
    element.click
    element.clear
    element.send_keys(params[:value])
    sleep 2
    #instance.find_element({ partial_link_text: params[:value] } ).click
    instance.execute_script("$(\"#global-search-result a:contains('#{params[:value]}') .nav-tab-icon\").click()")
    name = instance.find_elements({ css: '.active h1' })[0].text
    if name !~ /#{params[:value]}/
      screenshot(browser: instance, comment: 'organization_open_by_search_failed')
      fail "unable to search/find org #{params[:value]}!"
    end
    assert(true, "org #{params[:value]} found")
    sleep 2
    true
  end

=begin

  user_open_by_search(
    browser: browser2,
    value: 'some value',
  )

=end

  def user_open_by_search(params = {})
    switch_window_focus(params)
    log('user_open_by_search', params)

    instance = params[:browser] || @browser

    element = instance.find_elements({ css: '#global-search' })[0]
    element.click
    element.clear
    element.send_keys(params[:value])
    sleep 3
    #instance.find_element({ partial_link_text: params[:value] }).click
    instance.execute_script("$(\"#global-search-result a:contains('#{params[:value]}') .nav-tab-icon\").click()")
    name = instance.find_elements({ css: '.active h1' })[0].text
    if name !~ /#{params[:value]}/
      screenshot(browser: instance, comment: 'user_open_by_search_failed')
      fail "unable to search/find user #{params[:value]}!"
    end
    assert(true, "user #{params[:term]} found")
    sleep 2
    true
  end

=begin

  user_create(
    browser: browser2,
    data: {
      #login:    'some login' + random,
      firstname: 'Manage Firstname' + random,
      lastname:  'Manage Lastname' + random,
      email:     user_email,
      password:  'some-pass',
    },
  )

=end

  def user_create(params = {})
    switch_window_focus(params)
    log('user_create', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    instance.find_elements({ css: 'a[href="#manage"]' })[0].click
    sleep 1
    instance.find_elements({ css: 'a[href="#manage/users"]' })[0].click
    sleep 2
    instance.find_elements({ css: 'a[data-type="new"]' })[0].click
    sleep 2
    element = instance.find_elements({ css: '.modal input[name=firstname]' })[0]
    element.clear
    element.send_keys(data[:firstname])
    element = instance.find_elements({ css: '.modal input[name=lastname]' })[0]
    element.clear
    element.send_keys(data[:lastname])
    element = instance.find_elements({ css: '.modal input[name=email]' })[0]
    element.clear
    element.send_keys(data[:email])
    element = instance.find_elements({ css: '.modal input[name=password]' })[0]
    element.clear
    element.send_keys(data[:password])
    element = instance.find_elements({ css: '.modal input[name=password_confirm]' })[0]
    element.clear
    element.send_keys(data[:password])
    instance.find_elements({ css: '.modal input[name="role_ids"][value="3"]' })[0].click
    instance.find_elements({ css: '.modal button.js-submit' })[0].click
    sleep 3.5
    set(
      browser: instance,
      css: '.content .js-search',
      value: data[:email],
    )
    watch_for(
      browser: instance,
      css: 'body',
      value: data[:lastname],
    )

    assert(true, 'user created')
  end

=begin

  sla_create(
    browser: browser2,
    data: {
       name: 'some sla' + random,
       first_response_time_in_text: 61
    },
  )

=end

  def sla_create(params = {})
    switch_window_focus(params)
    log('sla_create', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    instance.find_elements({ css: 'a[href="#manage"]' })[0].click
    sleep 1
    instance.find_elements({ css: 'a[href="#manage/slas"]' })[0].click
    sleep 2
    instance.find_elements({ css: 'a.js-new' })[0].click
    sleep 2
    element = instance.find_elements({ css: '.modal input[name=name]' })[0]
    element.clear
    element.send_keys(data[:name])
    element = instance.find_elements({ css: '.modal input[name=first_response_time_in_text]' })[0]
    element.clear
    element.send_keys(data[:first_response_time_in_text])
    instance.find_elements({ css: '.modal button.js-submit' })[0].click
    (1..8).each {
      element = instance.find_elements({ css: 'body' })[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert(true, 'sla created')
        return true
      end
      sleep 1
    }
    screenshot(browser: instance, comment: 'sla_create_failed')
    fail 'sla creation failed'
  end

=begin

  text_module_create(
    browser: browser2,
    data: {
      name:     'some sla' + random,
      keywords: 'some keywords',
      content:  'some content',
    },
  )

=end

  def text_module_create(params = {})
    switch_window_focus(params)
    log('text_module_create', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    instance.find_elements({ css: 'a[href="#manage"]' })[0].click
    sleep 1
    instance.find_elements({ css: 'a[href="#manage/text_modules"]' })[0].click
    sleep 2
    instance.find_elements({ css: 'a[data-type="new"]' })[0].click
    sleep 2
    element = instance.find_elements({ css: '.modal input[name=name]' })[0]
    element.clear
    element.send_keys(data[:name])
    element = instance.find_elements({ css: '.modal input[name=keywords]' })[0]
    element.clear
    element.send_keys(data[:keywords])
    element = instance.find_elements({ css: '.modal textarea[name=content]' })[0]
    element.clear
    element.send_keys(data[:content])
    instance.find_elements({ css: '.modal button.js-submit' })[0].click
    (1..8).each {
      element = instance.find_elements({ css: 'body' })[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert(true, 'text module created')
        return true
      end
      sleep 1
    }
    screenshot(browser: instance, comment: 'text_module_create_failed')
    fail 'text module creation failed'
  end

=begin

  signature_create(
    browser: browser2,
    data: {
      name: 'some sla' + random,
      body: 'some body',
    },
  )

=end

  def signature_create(params = {})
    switch_window_focus(params)
    log('signature_create', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    instance.find_elements({ css: 'a[href="#manage"]' })[0].click
    sleep 1
    instance.find_elements({ css: 'a[href="#channels/email"]' })[0].click
    sleep 1
    instance.find_elements({ css: 'a[href="#c-signature"]' })[0].click
    sleep 8
    instance.find_elements({ css: '#content #c-signature a[data-type="new"]' })[0].click
    sleep 2
    element = instance.find_elements({ css: '.modal input[name=name]' })[0]
    element.clear
    element.send_keys(data[:name])
    element = instance.find_elements({ css: '.modal textarea[name=body]' })[0]
    element.clear
    element.send_keys(data[:body])
    instance.find_elements({ css: '.modal button.js-submit' })[0].click
    (1..12).each {
      element = instance.find_elements({ css: 'body' })[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert(true, 'signature created')
        return true
      end
      sleep 1
    }
    screenshot(browser: instance, comment: 'signature_create_failed')
    fail 'signature creation failed'
  end

=begin

  group_create(
    browser: browser2,
    data: {
      name:      'some sla' + random,
      signature: 'some signature bame',
      member:    [
        'some_user_login',
      ],
    },
  )

=end

  def group_create(params = {})
    switch_window_focus(params)
    log('group_create', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    instance.find_elements({ css: 'a[href="#manage"]' })[0].click
    sleep 0.5
    instance.find_elements({ css: 'a[href="#manage/groups"]' })[0].click
    sleep 2
    instance.find_elements({ css: 'a[data-type="new"]' })[0].click
    sleep 2
    element = instance.find_elements({ css: '.modal input[name=name]' })[0]
    element.clear
    element.send_keys(data[:name])
    element = instance.find_elements({ css: '.modal select[name="email_address_id"]' })[0]
    dropdown = Selenium::WebDriver::Support::Select.new(element)
    dropdown.select_by(:index, 1)
    #dropdown.select_by(:text, action[:group])
    if data[:signature]
      element = instance.find_elements({ css: '.modal select[name="signature_id"]' })[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by(:text, data[:signature])
    end
    instance.find_elements({ css: '.modal button.js-submit' })[0].click
    (1..12).each {
      element = instance.find_elements({ css: 'body' })[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert(true, 'group created')

        # add member
        if data[:member]
          data[:member].each {|login|
            instance.find_elements({ css: 'a[href="#manage"]' })[0].click
            sleep 0.5
            instance.find_elements({ css: 'a[href="#manage/users"]' })[0].click
            sleep 3
            element = instance.find_elements({ css: '#content [name="search"]' })[0]
            element.clear
            element.send_keys(login)
            sleep 3
            #instance.find_elements({ :css => '#content table [data-id]' })[0].click
            instance.execute_script('$("#content table [data-id] td").first().click()')
            sleep 3
            #instance.find_elements({ :css => 'label:contains(" ' + action[:name] + '")' })[0].click
            instance.execute_script('$(\'label:contains(" ' + data[:name] + '")\').first().click()')
            instance.find_elements({ css: '.modal button.js-submit' })[0].click
          }
        end
      end
      sleep 1
      return true
    }
    screenshot(browser: instance, comment: 'group_create_failed')
    fail 'group creation failed'
  end

  def quote(string)
    string_quoted = string
    string_quoted.gsub!(/&/, '&amp;')
    string_quoted.gsub!(/</, '&lt;')
    string_quoted.gsub!(/>/, '&gt;')
    string_quoted
  end

  def switch_window_focus(params)
    instance = params[:browser] || @browser
    if instance != @last_used_browser
      log('switch browser window focus', {})
      instance.switch_to.window(instance.window_handles.first)
    end
    @last_used_browser = instance
  end

  def log(method, params)
    return if !@@debug
    return if params[:mute_log]
    puts "#{Time.zone.now}/#{method}: #{params.inspect}"
  end
end
