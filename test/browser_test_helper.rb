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
      # currently console log not working for firefox
      # https://github.com/SeleniumHQ/selenium/issues/1161
      #browser_profile['loggingPref']              = { browser: :all }
    elsif browser == 'chrome'

      # profile are only working on remote selenium
      if ENV['REMOTE_URL']
        browser_profile = Selenium::WebDriver::Chrome::Profile.new
        browser_profile['intl.accept_languages'] = 'en'
        browser_profile['loggingPref']           = { browser: :all }
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

    # avoid "Cannot read property 'get_Current' of undefined" issues
    (1..5).each { |count|
      begin
        local_browser = browser_instance_remote
        break
      rescue
        wait_until_ready = rand(9) + 5
        sleep wait_until_ready
        log('browser_instance', { rescure: true, count: count, sleep: wait_until_ready })
      end
    }

    local_browser
  end

  def browser_instance_remote
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
    browser_instance_preferences(local_browser)

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
    browser_width = ENV['BROWSER_WIDTH'] || 1024
    browser_height = ENV['BROWSER_HEIGHT'] || 800
    local_browser.manage.window.resize_to(browser_width, browser_height)
    if ENV['REMOTE_URL'] !~ /saucelabs|(grid|ci)\.(zammad\.org|znuny\.com)/i
      if @browsers.count == 1
        local_browser.manage.window.move_to(0, 0)
      else
        local_browser.manage.window.move_to(browser_width, 0)
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
    filename = "tmp/#{Time.zone.now.strftime('screenshot_%Y_%m_%d__%H_%M_%S_%L')}_#{comment}#{instance.hash}.png"
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
    success:     false, #optional
  )

=end

  def login(params)
    switch_window_focus(params)
    log('login', params)
    instance = params[:browser] || @browser

    if params[:url]
      instance.get(params[:url])
    end

    # submit logs anyway
    instance.execute_script('App.Track.force()')

    element = instance.find_elements(css: '#login input[name="username"]')[0]
    if !element

      if params[:auto_wizard]
        watch_for(
          browser: instance,
          css:     'body',
          value:   'auto wizard is enabled',
          timeout: 10,
        )
        location(url: "#{browser_url}/#getting_started/auto_wizard")
        sleep 10
        login = instance.find_elements(css: '.user-menu .user a')[0].attribute('title')
        if login != params[:username]
          screenshot(browser: instance, comment: 'auto wizard login failed')
          raise 'auto wizard login failed'
        end
        assert(true, 'auto wizard login ok')

        clues_close(
          browser: instance,
          optional: true,
        )

        return
      end
      screenshot(browser: instance, comment: 'login_failed')
      raise 'No login box found'
    end

    screenshot(browser: instance, comment: 'login')

    element.clear
    element.send_keys(params[:username])

    element = instance.find_elements(css: '#login input[name="password"]')[0]
    element.clear
    element.send_keys(params[:password])

    if params[:remember_me]
      instance.find_elements(css: '#login .checkbox-replacement')[0].click
    end
    instance.find_elements(css: '#login button')[0].click

    sleep 4
    login_failed = false
    if !instance.find_elements(css: '.user-menu .user a')[0]
      login_failed = true
    else
      login = instance.find_elements(css: '.user-menu .user a')[0].attribute('title')
      if login != params[:username]
        login_failed = true
      end
    end
    if login_failed
      if params[:success] == false
        assert(true, 'login not successfull, like wanted')
        return true
      end
      screenshot(browser: instance, comment: 'login_failed')
      raise 'login failed'
    end

    if params[:success] == false
      raise 'login successfull but should not'
    end

    clues_close(
      browser: instance,
      optional: true,
    )

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

    click(
      browser: instance,
      css:  'a[href="#current_user"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  'a[href="#logout"]',
      mute_log: true,
    )

    5.times {
      sleep 1
      login = instance.find_elements(css: '#login')[0]

      next if !login
      screenshot(browser: instance, comment: 'logout_ok')
      assert(true, 'logout ok')
      return
    }
    screenshot(browser: instance, comment: 'logout_failed')
    raise 'no login box found, seems logout was not successfully!'
  end

=begin

  clues_close(
    browser: browser1,
    optional: false,
  )

=end

  def clues_close(params = {})
    switch_window_focus(params)
    log('clues_close', params)

    instance = params[:browser] || @browser

    clues = instance.find_elements(css: '.js-modal--clue .js-close')[0]
    if !params[:optional] && !clues
      screenshot(browser: instance, comment: 'no_clues')
      raise 'Unable to closes clues, no clues found!'
    end
    return if !clues
    instance.execute_script("$('.js-modal--clue .js-close').click()")
    assert(true, 'clues closed')
    sleep 1
  end

=begin

  notify_close(
    browser: browser1,
    optional: false,
  )

=end

  def notify_close(params = {})
    switch_window_focus(params)
    log('notify_close', params)

    instance = params[:browser] || @browser

    notify = instance.find_elements(css: '.noty_inline_layout_container.i-am-new')[0]
    if !params[:optional] && !notify
      screenshot(browser: instance, comment: 'no_notify')
      raise 'Unable to closes notify, no notify found!'
    end
    return if !notify
    notify.click
    assert(true, 'notify closed')
    sleep 1
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
    if !instance.find_elements(css: 'body')[0] || instance.find_elements(css: 'body')[0].text =~ /unavailable or too busy/i
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
    sleep 0.7
    current_url = instance.current_url
    if current_url !~ /#{Regexp.quote(params[:url])}/
      screenshot(browser: instance, comment: 'location_check_failed')
      raise "url #{current_url} is not matching #{params[:url]}"
    end
    assert(true, "url #{current_url} is matching #{params[:url]}")
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
    if !instance.find_elements(css: 'body')[0] || instance.find_elements(css: 'body')[0].text =~ /unavailable or too busy/i
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
    screenshot(browser: instance, comment: 'click_before')
    if params[:css]

      begin
        element = instance.find_elements(css: params[:css])[0]
        #if element
        #  instance.mouse.move_to(element)
        #end
        element.click
      rescue => e
        sleep 0.5

        # just try again
        log('click', { rescure: true })
        element = instance.find_elements(css: params[:css])[0]
        #if element
        #  instance.mouse.move_to(element)
        #end
        element.click
      end

    else
      sleep 0.5
      begin
        instance.find_elements(partial_link_text: params[:text])[0].click
      rescue => e
        sleep 0.5

        # just try again
        log('click', { rescure: true })
        instance.find_elements(partial_link_text: params[:text])[0].click
      end
    end
    sleep 0.2 if !params[:fast]
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
    screenshot(browser: instance, comment: 'scroll_to_before')
    execute(
      browser:  instance,
      js:       "\$('#{params[:css]}').get(0).scrollIntoView(#{position})",
      mute_log: params[:mute_log]
    )
    sleep 0.3
    screenshot(browser: instance, comment: 'scroll_to_after')
  end

=begin

  modal_ready(
    browser: browser1,
  )

=end

  def modal_ready(params = {})
    switch_window_focus(params)
    log('modal_ready', params)

    instance = params[:browser] || @browser

    screenshot(browser: instance, comment: 'modal_ready_before')
    sleep 3
    screenshot(browser: instance, comment: 'modal_ready_after')
  end

=begin

  modal_disappear(
    browser: browser1,
    timeout: 12, # default 8
  )

=end

  def modal_disappear(params = {})
    switch_window_focus(params)
    log('modal_disappear', params)

    instance = params[:browser] || @browser

    screenshot(browser: instance, comment: 'modal_disappear_before')
    watch_for_disappear(
      browser: instance,
      css:     '.modal',
      timeout: params[:timeout] || 8,
    )
    screenshot(browser: instance, comment: 'modal_disappear_after')
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
    raise "Invalid execute params #{params.inspect}"
  end

=begin

  exists(
    browser: browser1,
    css: '.some_class',
  )

  exists(
    displayed: false, # true|false
    browser: browser1,
    css: '.some_class',
  )

=end

  def exists(params)
    switch_window_focus(params)
    log('exists', params)

    instance = params[:browser] || @browser
    if !instance.find_elements(css: params[:css])[0]
      screenshot(browser: instance, comment: 'exists_failed')
      raise "#{params[:css]} dosn't exist, but should"
    end

    if params.key?(:displayed)
      if params[:displayed] == true && !instance.find_elements(css: params[:css])[0].displayed?
        raise "#{params[:css]} is not displayed, but should"
      end
      if params[:displayed] == false && instance.find_elements(css: params[:css])[0].displayed?
        raise "#{params[:css]} is displayed, but should not"
      end
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
    if instance.find_elements(css: params[:css])[0]
      screenshot(browser: instance, comment: 'exists_not_failed')
      raise "#{params[:css]} exists but should not"
    end
    true
  end

=begin

  set(
    browser:  browser1,
    css:      '.some_class',
    value:    true,
    slow:     false,
    blur:     true, # default false
    clear:    true, # todo | default: true
    no_click: true,
  )

=end

  def set(params)
    switch_window_focus(params)
    log('set', params)

    instance = params[:browser] || @browser
    screenshot(browser: instance, comment: 'set_before')

    element = instance.find_elements(css: params[:css])[0]
    if !params[:no_click]
      element.click
    end
    element.clear

    if !params[:slow]
      element.send_keys(params[:value])
    else
      element.send_keys('')
      keys = params[:value].to_s.split('')
      keys.each { |key|
        instance.action.send_keys(key).perform
      }
    end

    # it's not working stable with ff via selenium, use js
    if browser =~ /firefox/i && params[:css] =~ /\[data-name=/
      log('set_ff_check', params)
      value = instance.find_elements(css: params[:css])[0].text
      if value != params[:value]
        log('set_ff_check_failed_use_js', params)
        value_quoted = quote(params[:value])
        puts "DEBUG $('#{params[:css]}').html('#{value_quoted}').trigger('focusout')"
        instance.execute_script("$('#{params[:css]}').html('#{value_quoted}').trigger('focusout')")
      end
    end

    if params[:blur]
      instance.execute_script("$('#{params[:css]}').blur()")
    end

    sleep 0.2
    screenshot(browser: instance, comment: 'set_after')
  end

=begin

  select(
    browser:      browser1,
    css:          '.some_class',
    value:        'Some Value',
    deselect_all: false, # default false
  )

=end

  def select(params)
    switch_window_focus(params)
    log('select', params)

    instance = params[:browser] || @browser
    screenshot(browser: instance, comment: 'select_before')

    # searchable select
    element = instance.find_elements(css: "#{params[:css]}.js-shadow")[0]
    if element
      element = instance.find_elements(css: "#{params[:css]}.js-shadow + .js-input")[0]
      element.click
      element.clear
      sleep 0.4
      element.send_keys(params[:value])
      sleep 0.2
      element.send_keys(:enter)
      sleep 0.2
      return
    end

    # native select
    begin
      element  = instance.find_elements(css: params[:css])[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      if params[:deselect_all]
        dropdown.deselect_all
      end
      dropdown.select_by(:text, params[:value])
      #puts "select - #{params.inspect}"
    rescue
      sleep 0.4

      # just try again
      log('select', { rescure: true })
      element  = instance.find_elements(css: params[:css])[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      if params[:deselect_all]
        dropdown.deselect_all
      end
      dropdown.select_by(:text, params[:value])
      #puts "select2 - #{params.inspect}"
    end
    sleep 0.4
    screenshot(browser: instance, comment: 'select_after')
  end

=begin

  switch(
    browser: browser1,
    css:  '.some_class',
    type: 'on', # 'off'
    no_check: true, # do not check is switch has changed, in case if js alert
  )

=end

  def switch(params)
    switch_window_focus(params)
    log('switch', params)

    instance = params[:browser] || @browser
    screenshot(browser: instance, comment: 'switch_before')

    element = instance.find_elements(css: "#{params[:css]} input[type=checkbox]")[0]
    checked = element.attribute('checked')

    if !checked
      if params[:type] == 'on'
        instance.find_elements(css: "#{params[:css]} label")[0].click
        sleep 2

        if params[:no_check] != true
          element = instance.find_elements(css: "#{params[:css]} input[type=checkbox]")[0]
          checked = element.attribute('checked')
          raise 'Switch not on!' if !checked
        end
      end
    elsif params[:type] == 'off'
      instance.find_elements(css: "#{params[:css]} label")[0].click
      sleep 2

      if params[:no_check] != true
        element = instance.find_elements(css: "#{params[:css]} input[type=checkbox]")[0]
        checked = element.attribute('checked')
        raise 'Switch not off!' if checked
      end
    end
    screenshot(browser: instance, comment: 'switch_after')
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
    screenshot(browser: instance, comment: 'check_before')

    instance.execute_script("if (!$('#{params[:css]}').prop('checked')) { $('#{params[:css]}').click() }")
    #element = instance.find_elements(css: params[:css])[0]
    #checked = element.attribute('checked')
    #element.click if !checked
    screenshot(browser: instance, comment: 'check_after')
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
    screenshot(browser: instance, comment: 'uncheck_before')

    instance.execute_script("if ($('#{params[:css]}').prop('checked')) { $('#{params[:css]}').click() }")
    #element = instance.find_elements(css: params[:css])[0]
    #checked = element.attribute('checked')
    #element.click if checked
    screenshot(browser: instance, comment: 'uncheck_after')
  end

=begin

  sendkey(
    browser: browser1,
    value:   :enter,
    slow:    false, # default false
  )

=end

  def sendkey(params)
    switch_window_focus(params)
    log('sendkey', params)

    instance = params[:browser] || @browser
    element = nil
    if params[:css]
      element = instance.find_elements(css: params[:css])[0]
    end
    screenshot(browser: instance, comment: 'sendkey_before')
    if params[:value].class == Array
      params[:value].each { |key|
        if element
          element.send_keys(key)
        else
          instance.action.send_keys(key).perform
        end
      }
      screenshot(browser: instance, comment: 'sendkey_after')
      return
    end

    if element
      element.send_keys(params[:value])
    else
      instance.action.send_keys(params[:value]).perform
    end
    if params[:slow]
      sleep 1.5
    else
      sleep 0.2
    end
    screenshot(browser: instance, comment: 'sendkey_after')
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
    element  = instance.find_elements(css: params[:css])[0]

    if params[:css] =~ /select/
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      success  = false
      if dropdown.selected_options
        dropdown.selected_options.each { |option|
          if option.text == params[:value]
            success = true
          end
        }
      end
      if params[:should_not_match]
        if success
          screenshot(browser: instance, comment: 'match_failed')
          raise "should not match '#{params[:value]}' in select list, but is matching"
        end
      elsif !success
        screenshot(browser: instance, comment: 'match_failed')
        raise "not matching '#{params[:value]}' in select list"
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
        screenshot(browser: instance, comment: 'match_failed')
        raise "matching '#{params[:value]}' in content '#{text}' but should not!"
      end
    elsif !params[:should_not_match]
      screenshot(browser: instance, comment: 'match_failed')
      raise "not matching '#{params[:value]}' in content '#{text}' but should!"
    end
    sleep 0.2
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

set type of task (closeTab, closeNextInOverview, stayOnTab)

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
      instance.find_elements(css: '.content.active .js-secondaryActionButtonLabel')[0].click
      instance.find_elements(css: ".content.active .js-secondaryActionLabel[data-type=#{params[:type]}]")[0].click
      return
    end
    raise "Unknown params for task_type: #{params.inspect}"
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
    cookies.each { |cookie|
      #puts "CCC #{cookie.inspect}"
      # :name=>"_zammad_session_c25832f4de2", :value=>"adc31cd21615cb0a7ab269184ec8b76f", :path=>"/", :domain=>"localhost", :expires=>nil, :secure=>false}
      next if cookie[:name] !~ /#{params[:name]}/i

      if params.key?(:value) && cookie[:value].to_s =~ /#{params[:value]}/i
        assert(true, "matching value '#{params[:value]}' in cookie '#{cookie}'")
      else
        raise "not matching value '#{params[:value]}' in cookie '#{cookie}'"
      end
      if params.key?(:expires) && cookie[:expires].to_s =~ /#{params[:expires]}/i
        assert(true, "matching expires '#{params[:expires].inspect}' in cookie '#{cookie}'")
      else
        raise "not matching expires '#{params[:expires]}' in cookie '#{cookie}'"
      end

      return if !params[:should_not_exist]

      raise "cookie with name '#{params[:name]}' should not exist, but exists '#{cookies}'"
    }
    if params[:should_not_exist]
      assert(true, "cookie with name '#{params[:name]}' is not existing")
      return
    end
    raise "not matching name '#{params[:name]}' in cookie '#{cookies}'"
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
      raise "not matching '#{params[:value]}' in title '#{title}'"
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
        title = instance.find_elements(css: '.tasks .is-active')[0].text.strip
        if title =~ /#{data[:title]}/i
          assert(true, "matching '#{data[:title]}' in title '#{title}'")
        else
          screenshot(browser: instance, comment: 'verify_task_failed')
          raise "not matching '#{data[:title]}' in title '#{title}'"
        end
      end

      # verify modified
      if data.key?(:modified)
        exists      = instance.find_elements(css: '.tasks .is-active')[0]
        is_modified = instance.find_elements(css: '.tasks .is-modified')[0]
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
            screenshot(browser: instance, comment: 'verify_task_failed')
            raise "task '#{data[:title]}' not exists, should not modified"
          else
            screenshot(browser: instance, comment: 'verify_task_failed')
            raise "task '#{data[:title]}' is not modifed"
          end
        elsif !is_modified
          assert(true, "task '#{data[:title]}' is modifed")
        elsif !exists
          screenshot(browser: instance, comment: 'verify_task_failed')
          raise "task '#{data[:title]}' not exists, should be not modified"
        else
          screenshot(browser: instance, comment: 'verify_task_failed')
          raise "task '#{data[:title]}' is modifed, but should not"
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

  def open_task(params = {})
    switch_window_focus(params)
    log('open_task', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    element = instance.find_elements(partial_link_text: data[:title])[0]
    if !element
      screenshot(browser: instance, comment: 'open_task_failed')
      raise "no task with title '#{data[:title]}' found"
    end
    element.click
    true
  end

=begin

  close_task(
    browser: browser1,
    data: {
      title: 'some title',
    },
    discard_changes: true,
  )

=end

  def close_task(params = {})
    switch_window_focus(params)
    log('close_task', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    element = instance.find_elements(partial_link_text: data[:title])[0]
    if !element
      screenshot(browser: instance, comment: 'close_task_failed')
      raise "no task with title '#{data[:title]}' found"
    end

    instance.mouse.move_to(element)
    sleep 0.1
    instance.execute_script("$('.navigation .tasks .task:contains(\"#{data[:title]}\") .js-close').click()")

    # accept task close warning
    if params[:discard_changes]
      modal_ready(browser: instance)
      instance.find_elements(css: '.modal button.js-submit')[0].click
      modal_disappear(browser: instance)
    end

    true
  end

=begin

  file_upload(
    browser: browser1,
    css:     '.content.active .attachmentPlaceholder-inputHolder input'
    files:   ['path/in/home/some_file.ext'], # 'test/fixtures/test1.pdf'
  )

=end

  def file_upload(params = {})
    switch_window_focus(params)
    log('file_upload', params)

    instance = params[:browser] || @browser

    params[:files].each { |file|
      instance.find_elements(css: params[:css])[0].send_keys "#{Rails.root}/#{file}"
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
      element = instance.find_elements(css: params[:css])[0]
      if element #&& element.displayed?
        begin

          # watch for selector
          if !params[:attribute] && !params[:value]
            assert(true, "'#{params[:css]}' found")
            sleep 0.5
            return true

          # match pn attribute
          else
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
          end
        rescue
          # try again
        end
      end
      sleep 0.5
    }
    screenshot(browser: instance, comment: 'watch_for_failed')
    if !params[:attribute] && !params[:value]
      raise "'#{params[:css]}' not found"
    end
    raise "'#{params[:value]}' not found in '#{text}'"
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
      element = instance.find_elements(css: params[:css])[0]
      if !element #|| element.displayed?
        assert(true, 'not found')
        sleep 1
        return true
      end
      if params[:value]
        begin
          text = instance.find_elements(css: params[:css])[0].text
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
    raise "#{params[:css]}) still exsists"
  end

=begin

  shortcut(
    browser: browser1,
    key: 'x',
  )

=end

  def shortcut(params = {})
    switch_window_focus(params)
    log('shortcut', params)
    instance = params[:browser] || @browser
    screenshot(browser: instance, comment: 'shortcut_before')
    instance.action.key_down(:control)
            .key_down(:shift)
            .send_keys(params[:key])
            .key_up(:shift)
            .key_up(:control)
            .perform
    screenshot(browser: instance, comment: 'shortcut_after')
  end

=begin

  window_keys(
    browser: browser1,
    value: 'x',
  )

=end

  def window_keys(params = {})
    switch_window_focus(params)
    log('window_keys', params)
    instance = params[:browser] || @browser
    instance.action.send_keys(params[:value]).perform
  end

=begin

  tasks_close_all(
    browser: browser1,
  )

=end

  def tasks_close_all(params = {})
    switch_window_focus(params)
    log('tasks_close_all', params)

    instance = params[:browser] || @browser

    99.times do
      #sleep 0.5
      begin
        if instance.find_elements(css: '.navigation .tasks .task:first-child')[0]
          instance.mouse.move_to(instance.find_elements(css: '.navigation .tasks .task:first-child')[0])
          sleep 0.1
          click_element = instance.find_elements(css: '.navigation .tasks .task:first-child .js-close')[0]
          if click_element
            click_element.click

            # accept task close warning
            if instance.find_elements(css: '.modal button.js-submit')[0]
              sleep 0.4
              instance.find_elements(css: '.modal button.js-submit')[0].click
            end
          end
        else
          break
        end
      rescue
        # try again
      end
    end
    assert(true, 'all tasks closed')
  end

=begin

  close_online_notitifcation(
    browser: browser1,
    data: {
      #title: 'some title',
      position: 3,
    },
  )

=end

  def close_online_notitifcation(params = {})
    switch_window_focus(params)
    log('close_online_notitifcation', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    if data[:title]
      element = instance.find_elements(partial_link_text: data[:title])[0]
      if !element
        screenshot(browser: instance, comment: 'close_online_notitifcation')
        raise "no online notification with title '#{data[:title]}' found"
      end
      instance.mouse.move_to(element)
      sleep 0.1
      instance.execute_script("$('.js-notificationsContainer .js-items .js-item .activity-text:contains(\"#{data[:title]}\") .js-remove').first().click()")

    else
      css = ".js-notificationsContainer .js-items .js-item:nth-child(#{data[:position]})"
      element = instance.find_elements(css: css)[0]
      if !element
        screenshot(browser: instance, comment: 'close_online_notitifcation')
        raise "no online notification with postion '#{css}' found"
      end

      instance.mouse.move_to(element)
      sleep 0.1
      instance.find_elements(css: "#{css} .js-remove")[0].click
    end

    true
  end

=begin

  online_notitifcation_close_all(
    browser: browser1,
  )

=end

  def online_notitifcation_close_all(params = {})
    switch_window_focus(params)
    log('online_notitifcation_close_all', params)

    instance = params[:browser] || @browser

    99.times do
      sleep 0.5
      begin
        if instance.find_elements(css: '.js-notificationsContainer .js-item:first-child')[0]
          instance.mouse.move_to(instance.find_elements(css: '.js-notificationsContainer .js-item:first-child')[0])
          sleep 0.1
          click_element = instance.find_elements(css: '.js-notificationsContainer .js-item:first-child .js-remove')[0]
          if click_element
            click_element.click
          end
        else
          break
        end
      rescue
        # try again
      end
    end
    assert(true, 'all online notification closed')
  end

=begin

  empty_search(
    browser: browser1,
  )

=end

  def empty_search(params = {})
    switch_window_focus(params)
    log('empty_search', params)

    instance = params[:browser] || @browser

    # empty search box by x
    begin
      instance.find_elements(css: '.search .js-emptySearch')[0].click
    rescue

      # in issues with ff & selenium, sometimes exeption appears
      # "Element is not currently visible and so may not be interacted with"
      log('empty_search via js')
      instance.execute_script('$(".search .js-emptySearch").click()')
    end
    sleep 0.5
    text = instance.find_elements(css: '#global-search')[0].attribute('value')
    if !text
      raise '#global-search is not empty!'
    end

    true
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

    element = instance.find_elements(css: params[:css] + ' input[name="customer_id_completion"]')[0]
    element.click
    element.clear

    element.send_keys(params[:customer])
    sleep 2.5

    element.send_keys(:enter)
    #instance.find_elements(css: params[:css] + ' .recipientList-entry.js-object.is-active')[0].click
    sleep 0.4
    assert(true, 'ticket_customer_select')
  end

=begin

  overview_create(
    browser: browser1,
    data: {
      name: name,
      roles: ['Agent'],
      selector: {
        'Priority': '1 low',
      },
      'order::direction' => 'down',
    }
  )

=end

  def overview_create(params)
    switch_window_focus(params)
    log('overview_create', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    click(
      browser: instance,
      css:  'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[href="#manage/overviews"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[data-type="new"]',
      mute_log: true,
    )
    modal_ready(browser: instance)
    if data[:name]
      set(
        browser:  instance,
        css:      '.modal input[name=name]',
        value:    data[:name],
        mute_log: true,
      )
    end

    if data[:roles]
      99.times do
        begin
          element = instance.find_elements(css: '.modal .js-selected[data-name=role_ids] .js-option:not(.is-hidden)')[0]
          break if !element
          element.click
          sleep 0.1
        end
      end
      data[:roles].each { |role|
        instance.execute_script("$(\".modal [data-name=role_ids] .js-pool .js-option:not(.is-hidden):contains('#{role}')\").first().click()")
      }
    end

    if data[:selector]
      data[:selector].each { |key, value|
        select(
          browser:  instance,
          css:      '.modal .ticket_selector .js-attributeSelector select',
          value:    key,
          mute_log: true,
        )
        sleep 0.5
        select(
          browser:      instance,
          css:          '.modal .ticket_selector .js-value select',
          value:        value,
          deselect_all: true,
          mute_log:     true,
        )
      }
    end

    if data['order::direction']
      select(
        browser:  instance,
        css:      '.modal select[name="order::direction"]',
        value:    data['order::direction'],
        mute_log: true,
      )
    end

    instance.find_elements(css: '.modal button.js-submit')[0].click
    modal_disappear(browser: instance)
    11.times {
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert(true, 'overview created')
        overview = {
          name: name,
        }
        sleep 1
        return overview
      end
      sleep 1
    }
    screenshot(browser: instance, comment: 'overview_create_failed')
    raise 'overview creation failed'
  end

=begin

  overview_update(
    browser: browser1,
    data: {
      name: name,
      roles: ['Agent'],
      selector: {
        'Priority': '1 low',
      },
      'order::direction' => 'down',
    }
  )

=end

  def overview_update(params)
    switch_window_focus(params)
    log('overview_create', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    click(
      browser: instance,
      css: 'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css: '.content.active a[href="#manage/overviews"]',
      mute_log: true,
    )

    instance.execute_script("$(\".content.active td:contains('#{data[:name]}')\").first().click()")
    sleep 2

    if data[:name]
      set(
        browser:  instance,
        css:      '.modal input[name=name]',
        value:    data[:name],
        mute_log: true,
      )
    end
    if data[:roles]
      99.times do
        begin
          element = instance.find_elements(css: '.modal .js-selected[data-name=role_ids] .js-option:not(.is-hidden)')[0]
          break if !element
          element.click
          sleep 0.1
        end
      end
      data[:roles].each { |role|
        instance.execute_script("$(\".modal [data-name=role_ids] .js-pool .js-option:not(.is-hidden):contains('#{role}')\").first().click()")
      }
    end

    if data[:selector]
      data[:selector].each { |key, value|
        select(
          browser:  instance,
          css:      '.modal .ticket_selector .js-attributeSelector select',
          value:    key,
          mute_log: true,
        )
        sleep 0.5
        select(
          browser:      instance,
          css:          '.modal .ticket_selector .js-value select',
          value:        value,
          deselect_all: true,
          mute_log:     true,
        )
      }
    end

    if data['order::direction']
      select(
        browser:  instance,
        css:      '.modal select[name="order::direction"]',
        value:    data['order::direction'],
        mute_log: true,
      )
    end

    instance.find_elements(css: '.modal button.js-submit')[0].click
    modal_disappear(browser: instance)
    11.times {
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert(true, 'overview updated')
        overview = {
          name: name,
        }
        sleep 1
        return overview
      end
      sleep 1
    }
    screenshot(browser: instance, comment: 'overview_update_failed')
    raise 'overview update failed'
  end

=begin

  ticket = ticket_create(
    browser: browser1,
    data: {
      customer: 'nico',
      group:    'Users', # optional / '-NONE-' # if group selection should not be shown
      priority: '2 normal',
      state:    'open',
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

  ticket = ticket_create(
    browser: browser1,
    data: {
      customer: 'nico',
      group:    'Users', # optional / '-NONE-' # if group selection should not be shown
      priority: '2 normal',
      state:    'open',
      title:    'overview #1',
      body:     'overview #1',
    },
    custom_data_select: {
      key1: 'some value',
    },
    custom_data_input: {
      key1: 'some value',
    },
    disable_group_check: true,
  )

=end

  def ticket_create(params)
    switch_window_focus(params)
    log('ticket_create', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    click(
      browser: instance,
      css: 'a[href="#new"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css: 'a[href="#ticket/create"]',
      mute_log: true,
    )

    found = false
    7.times {
      element = instance.find_elements(css: '.content.active .newTicket')[0]
      if element
        found = true
        break
      end
      sleep 1
    }
    if !found
      screenshot(browser: instance, comment: 'ticket_create_failed')
      raise 'no ticket create screen found!'
    end

    if data[:group]
      if data[:group] == '-NONE-'

        # check if owner selection exists
        count = instance.find_elements(css: '.content.active .newTicket select[name="group_id"] option').count
        if count.nonzero?
          instance.find_elements(css: '.content.active .newTicket select[name="group_id"] option').each { |element|
            log('ticket_create invalid group count', text: element.text)
          }
        end
        assert_equal(0, count, 'owner selection should not be showm')

        # check count of agents, should be only 3 / - selection + master + agent on init screen
        count = instance.find_elements(css: '.content.active .newTicket select[name="owner_id"] option').count
        if count != 3
          instance.find_elements(css: '.content.active .newTicket select[name="owner_id"] option').each { |element|
            log('ticket_create invalid owner count', text: element.text)
          }
        end
        assert_equal(3, count, 'check if owner selection is - selection + master + agent per default')
      else

        # check count of agents, should be only 1 / - selection on init screen
        if !params[:disable_group_check]
          count = instance.find_elements(css: '.content.active .newTicket select[name="owner_id"] option').count
          if count != 1
            instance.find_elements(css: '.content.active .newTicket select[name="owner_id"] option').each { |element|
              log('ticket_create invalid owner count', text: element.text)
            }
          end
          assert_equal(1, count, 'check if owner selection is empty per default')
        end
        select(
          browser:  instance,
          css:      '.content.active .newTicket select[name="group_id"]',
          value:    data[:group],
          mute_log: true,
        )
        sleep 0.2
      end
    end
    if data[:priority]
      select(
        browser:  instance,
        css:      '.content.active .newTicket select[name="priority_id"]',
        value:    data[:priority],
        mute_log: true,
      )
    end
    if data[:state]
      select(
        browser:  instance,
        css:      '.content.active .newTicket select[name="state_id"]',
        value:    data[:state],
        mute_log: true,
      )
    end
    if data[:title]
      set(
        browser:  instance,
        css:      '.content.active .newTicket input[name="title"]',
        value:    data[:title],
        clear:    true,
        mute_log: true,
      )
    end
    if data[:body]
      set(
        browser:  instance,
        css:      '.content.active .newTicket div[data-name=body]',
        value:    data[:body],
        clear:    true,
        mute_log: true,
      )
    end
    if data[:customer]
      element = instance.find_elements(css: '.content.active .newTicket input[name="customer_id_completion"]')[0]
      element.click
      element.clear

      # ff issue, sometimes focus event gets dropped
      # if drowdown is not open, try it again
      if !instance.find_elements(css: '.content.active .newTicket .js-recipientDropdown.open')[0]
        instance.execute_script('$(".active .newTicket .js-recipientDropdown").addClass("open")')
      end

      element.send_keys(data[:customer])
      sleep 2.5

      element.send_keys(:enter)
      sleep 0.4
      # ff issue, sometimes enter event gets dropped
      # take user manually
      if instance.find_elements(css: '.content.active .newTicket .js-recipientDropdown.open')[0]
        instance.find_elements(css: '.content.active .newTicket .recipientList-entry.js-object.is-active')[0].click
        sleep 0.4
      end
    end

    if params[:custom_data_select]
      params[:custom_data_select].each { |local_key, local_value|
        select(
          browser: instance,
          css:     ".content.active .newTicket select[name=\"#{local_key}\"]",
          value:   local_value,
        )
      }
    end
    if params[:custom_data_input]
      params[:custom_data_input].each { |local_key, local_value|
        set(
          browser: instance,
          css:     ".content.active .newTicket input[name=\"#{local_key}\"]",
          value:   local_value,
          clear:   true,
        )
      }
    end

    if data[:attachment]
      file_upload(
        browser: instance,
        css: '.content.active .text-1',
        value: 'some text',
      )
    end

    if params[:do_not_submit]
      assert(true, 'ticket created without submit')
      return
    end
    sleep 0.5
    #instance.execute_script('$(".content.active .newTicket form").submit();')
    click(
      browser: instance,
      css:  '.content.active .newTicket button.js-submit',
      mute_log: true,
    )

    sleep 1
    9.times {
      if instance.current_url =~ /#{Regexp.quote('#ticket/zoom/')}/
        assert(true, 'ticket created')
        sleep 2.5
        id = instance.current_url
        id.gsub!(//,)
        id.gsub!(%r{^.+?/(\d+)$}, '\\1')

        element = instance.find_elements(css: '.content.active .ticketZoom-header .ticket-number')[0]
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
    raise "ticket creation failed, can't get zoom url (current url is '#{instance.current_url}')"
  end

=begin

  ticket_update(
    browser: browser1,
    data: {
      title:    '',
      customer: 'some_customer@example.com',
      body:     'some body',
      group:    'some group', # optional
      priority: '1 low',
      state:    'closed',
    },
    do_not_submit: true,
  )

  ticket_update(
    browser: browser1,
    data: {
      title:    '',
      customer: 'some_customer@example.com',
      body:     'some body',
      group:    'some group', # optional
      priority: '1 low',
      state:    'closed',
    },
    custom_data_select: {
      key1: 'some value',
    },
    custom_data_input: {
      key1: 'some value',
    },
    do_not_submit: true,
    task_type: 'stayOnTab', # default: stayOnTab / possible: closeTab, closeNextInOverview, stayOnTab
  )

=end

  def ticket_update(params)
    switch_window_focus(params)
    log('ticket_update', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    if data[:title]
      #element = instance.find_elements(:css => '.content.active .ticketZoom-header .js-objectTitle')[0]
      #element.clear
      #sleep 0.5
      #element = instance.find_elements(:css => '.content.active .ticketZoom-header .js-objectTitle')[0]
      #element.send_keys(data[:title])
      #sleep 0.5
      #element.send_keys(:tab)

      instance.execute_script('$(".content.active .ticketZoom-header .js-objectTitle").focus()')
      instance.execute_script('$(".content.active .ticketZoom-header .js-objectTitle").text("' + data[:title] + '")')
      instance.execute_script('$(".content.active .ticketZoom-header .js-objectTitle").blur()')
      instance.execute_script('$(".content.active .ticketZoom-header .js-objectTitle").trigger("blur")')
      # {
      #   :where        => :instance2,
      #   :execute      => 'sendkey',
      #   :css          => '.content.active .ticketZoom-header .js-objectTitle',
      #   :value        => 'TTT',
      # },
      # {
      #   :where        => :instance2,
      #   :execute      => 'sendkey',
      #   :css          => '.content.active .ticketZoom-header .js-objectTitle',
      #   :value        => :tab,
      # },
    end
    if data[:customer]

      # select tab
      click(browser: instance, css: '.content.active .tabsSidebar-tab[data-tab="customer"]')

      click(browser: instance, css: '.content.active div[data-tab="customer"] .js-actions .icon-arrow-down')
      click(browser: instance, css: '.content.active div[data-tab="customer"] .js-actions [data-type="customer-change"]')
      watch_for(
        browser: instance,
        css: '.modal',
        value: 'change',
      )

      element = instance.find_elements(css: '.modal input[name="customer_id_completion"]')[0]
      element.click
      element.clear

      element.send_keys(data[:customer])
      sleep 2.5

      element.send_keys(:enter)
      #instance.find_elements(css: '.modal .user_autocompletion .recipientList-entry.js-object.is-active')[0].click
      sleep 0.2

      click(browser: instance, css: '.modal .js-submit')

      modal_disappear(browser: instance)

      watch_for(
        browser: instance,
        css: '.content.active .tabsSidebar',
        value: data[:customer],
      )

      # select tab
      click(browser: instance, css: '.content.active .tabsSidebar-tab[data-tab="ticket"]')

    end
    if data[:body]
      set(
        browser:  instance,
        css:      '.content.active div[data-name=body]',
        value:    data[:body],
        no_click: true,
        mute_log: true,
      )

      # it's not working stable via selenium, use js
      value = instance.find_elements(css: '.content.active div[data-name=body]')[0].text
      if value != data[:body]
        body_quoted = quote(data[:body])
        instance.execute_script("$('.content.active div[data-name=body]').html('#{body_quoted}').trigger('focusout')")
      end

    end

    if data[:group]
      if data[:group] == '-NONE-'

        # check if owner selection exists
        count = instance.find_elements(css: '.content.active .sidebar select[name="group_id"] option').count
        assert_equal(0, count, 'owner selection should not be showm')

        # check count of agents, should be only 3 / - selection + master + agent on init screen
        count = instance.find_elements(css: '.content.active .sidebar select[name="owner_id"] option').count
        assert_equal(3, count, 'check if owner selection is - selection + master + agent per default')

      else
        select(
          browser:  instance,
          css:      '.content.active .sidebar select[name="group_id"]',
          value:    data[:group],
          mute_log: true,
        )
        sleep 0.2
      end
    end

    if data[:priority]
      select(
        browser:  instance,
        css:      '.content.active .sidebar select[name="priority_id"]',
        value:    data[:priority],
        mute_log: true,
      )
    end

    if data[:state]
      select(
        browser:  instance,
        css:      '.content.active .sidebar select[name="state_id"]',
        value:    data[:state],
        mute_log: true,
      )
    end

    if params[:custom_data_select]
      params[:custom_data_select].each { |local_key, local_value|
        select(
          browser: instance,
          css:     ".active .sidebar select[name=\"#{local_key}\"]",
          value:   local_value,
        )
      }
    end
    if params[:custom_data_input]
      params[:custom_data_input].each { |local_key, local_value|
        set(
          browser: instance,
          css:     ".active .sidebar input[name=\"#{local_key}\"]",
          value:   local_value,
          clear:   true,
        )
      }
    end

    if data[:state] || data[:group] || data[:body] || !params[:custom_data_select].empty? || !params[:custom_data_input].empty?
      found = nil
      9.times {

        break if found

        begin
          text = instance.find_elements(css: '.content.active .js-reset')[0].text
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
        raise 'no discard message found'
      end
    end

    task_type(
      browser: instance,
      type:    params[:task_type] || 'stayOnTab',
    )

    if params[:do_not_submit]
      assert(true, 'ticket updated without submit')
      return true
    end

    instance.find_elements(css: '.content.active .js-submit')[0].click

    # do not stay on tab
    if params[:task_type] == 'closeTab' || params[:task_type] == 'closeNextInOverview'
      sleep 1
      screenshot(browser: instance, comment: 'ticket_update')
      return
    end

    9.times {
      begin
        text = instance.find_elements(css: '.content.active .js-reset')[0].text
        if text.blank?
          screenshot(browser: instance, comment: 'ticket_update_ok')
          sleep 1
          return true
        end
      rescue
        # try again
      end
      sleep 1
    }
    screenshot(browser: instance, comment: 'ticket_update_failed')
    raise 'unable to update ticket'
  end

=begin

  ticket_verify(
    browser: browser1,
    data: {
      title: 'some title',
      body:  'some body',
##      group: 'some group',
##      state: 'closed',
      custom_data_select: {
        key1: 'some value',
      },
      custom_data_input: {
        key1: 'some value',
      },
    },
  )

=end

  def ticket_verify(params)
    switch_window_focus(params)
    log('ticket_verify', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    if data[:title]
      title = instance.find_elements(css: '.content.active .ticketZoom-header .js-objectTitle').first.text.strip
      if title =~ /#{data[:title]}/i
        assert(true, "matching '#{data[:title]}' in title '#{title}'")
      else
        raise "not matching '#{data[:title]}' in title '#{title}'"
      end
    end

    if data[:body]
      body = instance.find_elements(css: '.content.active [data-name="body"]').first.text.strip
      if body =~ /#{data[:body]}/i
        assert(true, "matching '#{data[:body]}' in body '#{body}'")
      else
        raise "not matching '#{data[:body]}' in body '#{body}'"
      end
    end

    if params[:custom_data_select]
      params[:custom_data_select].each { |local_key, local_value|
        element = instance.find_elements(css: ".active .sidebar select[name=\"#{local_key}\"] option[selected]").first
        value = element.text.strip
        if value =~ /#{local_value}/i
          assert(true, "matching '#{value}' in #{local_key} '#{local_value}'")
        else
          raise "not matching '#{value}' in #{local_key} '#{local_value}'"
        end
      }
    end
    if params[:custom_data_input]
      params[:custom_data_input].each { |local_key, local_value|
        element = instance.find_elements(css: ".active .sidebar input[name=\"#{local_key}\"]").first
        value = element.text.strip
        if value =~ /#{local_value}/i
          assert(true, "matching '#{value}' in #{local_key} '#{local_value}'")
        else
          raise "not matching '#{value}' in #{local_key} '#{local_value}'"
        end
      }
    end

    true
  end

=begin

  ticket_open_by_overview(
    browser: browser2,
    number:  ticket1[:number],
    link:    "#ticket/view/#{name}",
  )

  ticket_open_by_overview(
    browser: browser2,
    number:  ticket1[:number],
    text:    title,
    link:    "#ticket/view/#{name}",
  )

=end

  def ticket_open_by_overview(params)
    switch_window_focus(params)
    log('ticket_open_by_overview', params)

    instance = params[:browser] || @browser

    instance.find_elements(css: '.js-overviewsMenuItem')[0].click
    sleep 1
    execute(
      browser: instance,
      js: '$(".content.active .sidebar").css("display", "block")',
    )
    screenshot(browser: instance, comment: 'ticket_open_by_overview')
    instance.find_elements(css: ".content.active .sidebar a[href=\"#{params[:link]}\"]")[0].click
    sleep 1
    execute(
      browser: instance,
      js: '$(".content.active .sidebar").css("display", "none")',
    )
    screenshot(browser: instance, comment: 'ticket_open_by_overview_search')
    if params[:title]
      element = instance.find_elements(partial_link_text: params[:title])[0]
      if !element
        screenshot(browser: instance, comment: 'ticket_open_by_overview_no_ticket_failed')
        raise "unable to find ticket #{params[:title]} in overview #{params[:link]}!"
      end
    else
      element = instance.find_elements(partial_link_text: params[:number])[0]
      if !element
        screenshot(browser: instance, comment: 'ticket_open_by_overview_no_ticket_failed')
        raise "unable to find ticket #{params[:number]} in overview #{params[:link]}!"
      end
    end
    element.click
    sleep 1
    number = instance.find_elements(css: '.content.active .ticketZoom-header .ticket-number')[0].text
    if number !~ /#{params[:number]}/
      screenshot(browser: instance, comment: 'ticket_open_by_overview_open_failed_failed')
      raise "unable to open ticket #{params[:number]}!"
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
    element = instance.find_elements(css: '#global-search')[0]
    element.click
    element.clear
    element.send_keys(params[:number])
    sleep 3

    empty_search(browser: instance)

    # search by number again
    element = instance.find_elements(css: '#global-search')[0]
    element.click
    element.clear
    element.send_keys(params[:number])
    sleep 1

    # open ticket
    screenshot(browser: instance, comment: 'ticket_open_by_search')
    #instance.find_element(partial_link_text: params[:number] } ).click
    instance.execute_script("$(\".js-global-search-result a:contains('#{params[:number]}') .nav-tab-icon\").first().click()")
    sleep 1
    number = instance.find_elements(css: '.content.active .ticketZoom-header .ticket-number')[0].text
    if number !~ /#{params[:number]}/
      screenshot(browser: instance, comment: 'ticket_open_by_search_failed')
      raise "unable to search/find ticket #{params[:number]}!"
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
    element = instance.find_elements(css: '#global-search')[0]
    element.click
    element.clear
    element.send_keys(params[:title])
    sleep 3

    # open ticket
    screenshot(browser: instance, comment: 'ticket_open_by_title_search')
    #instance.find_element(partial_link_text: params[:title] } ).click
    instance.execute_script("$(\".js-global-search-result a:contains('#{params[:title]}') .nav-tab-icon\").click()")
    sleep 1
    title = instance.find_elements(css: '.content.active .ticketZoom-header .js-objectTitle')[0].text
    if title !~ /#{params[:title]}/
      screenshot(browser: instance, comment: 'ticket_open_by_title_failed')
      raise "unable to search/find ticket #{params[:title]}!"
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

    instance.find_elements(css: '.js-overviewsMenuItem')[0].click
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
    instance.find_elements(css: '.content.active .sidebar a[href]').each { |element|
      url = element.attribute('href')
      url.gsub!(%r{(http|https)://.+?/(.+?)$}, '\\2')
      overviews[url] = 0
      #puts url.inspect
      #puts element.inspect
    }
    overviews.each { |url, _value|
      count          = instance.find_elements(css: ".content.active .sidebar a[href=\"#{url}\"] .badge")[0].text
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

    element = instance.find_elements(css: '#global-search')[0]

    element.click
    element.clear
    element.send_keys(params[:value])
    sleep 3

    empty_search(browser: instance)

    element = instance.find_elements(css: '#global-search')[0]
    element.click
    element.clear
    element.send_keys(params[:value])
    sleep 2
    #instance.find_element(partial_link_text: params[:value] } ).click
    instance.execute_script("$(\".js-global-search-result a:contains('#{params[:value]}') .nav-tab-icon\").click()")
    sleep 1
    name = instance.find_elements(css: '.content.active h1')[0].text
    if name !~ /#{params[:value]}/
      screenshot(browser: instance, comment: 'organization_open_by_search_failed')
      raise "unable to search/find org #{params[:value]}!"
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

    element = instance.find_elements(css: '#global-search')[0]
    element.click
    element.clear
    element.send_keys(params[:value])
    sleep 3

    screenshot(browser: instance, comment: 'user_open_by_search')
    #instance.find_element(partial_link_text: params[:value]).click
    instance.execute_script("$(\".js-global-search-result a:contains('#{params[:value]}') .nav-tab-icon\").click()")
    sleep 1
    name = instance.find_elements(css: '.content.active h1')[0].text
    if name !~ /#{params[:value]}/
      screenshot(browser: instance, comment: 'user_open_by_search_failed')
      raise "unable to search/find user #{params[:value]}!"
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

    click(
      browser: instance,
      css:  'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[href="#manage/users"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[data-type="new"]',
      mute_log: true,
    )
    modal_ready(browser: instance)
    element = instance.find_elements(css: '.modal input[name=firstname]')[0]
    element.clear
    element.send_keys(data[:firstname])
    element = instance.find_elements(css: '.modal input[name=lastname]')[0]
    element.clear
    element.send_keys(data[:lastname])
    element = instance.find_elements(css: '.modal input[name=email]')[0]
    element.clear
    element.send_keys(data[:email])
    element = instance.find_elements(css: '.modal input[name=password]')[0]
    element.clear
    element.send_keys(data[:password])
    element = instance.find_elements(css: '.modal input[name=password_confirm]')[0]
    element.clear
    element.send_keys(data[:password])
    check(
      browser: instance,
      css:     '.modal input[name=role_ids][value=3]',
    )
    instance.find_elements(css: '.modal button.js-submit')[0].click
    modal_disappear(
      browser: instance,
      timeout: 10,
    )
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

    click(
      browser: instance,
      css:  'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[href="#manage/slas"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a.js-new',
      mute_log: true,
    )
    modal_ready(browser: instance)
    element = instance.find_elements(css: '.modal input[name=name]')[0]
    element.clear
    element.send_keys(data[:name])
    element = instance.find_elements(css: '.modal input[name=first_response_time_in_text]')[0]
    element.clear
    element.send_keys(data[:first_response_time_in_text])
    instance.find_elements(css: '.modal button.js-submit')[0].click
    modal_disappear(browser: instance)
    7.times {
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert(true, 'sla created')
        sleep 1
        return true
      end
      sleep 1
    }
    screenshot(browser: instance, comment: 'sla_create_failed')
    raise 'sla creation failed'
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

    click(
      browser: instance,
      css:  'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[href="#manage/text_modules"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[data-type="new"]',
      mute_log: true,
    )
    modal_ready(browser: instance)
    set(
      browser:  instance,
      css:      '.modal input[name=name]',
      value:    data[:name],
    )
    set(
      browser:  instance,
      css:      '.modal input[name=keywords]',
      value:    data[:keywords],
    )
    set(
      browser:  instance,
      css:      '.modal [data-name=content]',
      value:    data[:content],
    )
    instance.find_elements(css: '.modal button.js-submit')[0].click
    modal_disappear(browser: instance)
    7.times {
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert(true, 'text module created')
        sleep 1
        return true
      end
      sleep 1
    }
    screenshot(browser: instance, comment: 'text_module_create_failed')
    raise 'text module creation failed'
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

    click(
      browser: instance,
      css: 'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css: '.content.active a[href="#channels/email"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css: '.content.active a[href="#c-signature"]',
      mute_log: true,
    )
    sleep 4
    click(
      browser: instance,
      css: '.content.active #c-signature a[data-type="new"]',
      mute_log: true,
    )
    modal_ready(browser: instance)
    set(
      browser:  instance,
      css:      '.modal input[name=name]',
      value:    data[:name],
    )
    set(
      browser:  instance,
      css:      '.modal [data-name=body]',
      value:    data[:body],
    )
    instance.find_elements(css: '.modal button.js-submit')[0].click
    modal_disappear(browser: instance)
    11.times {
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert(true, 'signature created')
        sleep 1
        return true
      end
      sleep 1
    }
    screenshot(browser: instance, comment: 'signature_create_failed')
    raise 'signature creation failed'
  end

=begin

  group_create(
    browser: browser2,
    data: {
      name:      'some sla' + random,
      signature: 'some signature bame',
      member:    [
        {
          login: 'some_user_login',
          access: 'all',
        },
      ],
    },
  )

=end

  def group_create(params = {})
    switch_window_focus(params)
    log('group_create', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    click(
      browser: instance,
      css: 'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css: '.content.active a[href="#manage/groups"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css: '.content.active a[data-type="new"]',
      mute_log: true,
    )
    modal_ready(browser: instance)
    element = instance.find_elements(css: '.modal input[name=name]')[0]
    element.clear
    element.send_keys(data[:name])
    element = instance.find_elements(css: '.modal select[name="email_address_id"]')[0]
    dropdown = Selenium::WebDriver::Support::Select.new(element)
    dropdown.select_by(:index, 1)
    #dropdown.select_by(:text, action[:group])
    if data[:signature]
      element = instance.find_elements(css: '.modal select[name="signature_id"]')[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by(:text, data[:signature])
    end
    instance.find_elements(css: '.modal button.js-submit')[0].click
    modal_disappear(browser: instance)
    11.times {
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert(true, 'group created')
        modal_disappear(browser: instance) # wait until modal has gone

        # add member
        if data[:member]
          data[:member].each { |member|
            instance.find_elements(css: 'a[href="#manage"]')[0].click
            sleep 1
            instance.find_elements(css: '.content.active a[href="#manage/users"]')[0].click
            sleep 3
            element = instance.find_elements(css: '.content.active [name="search"]')[0]
            element.clear
            element.send_keys(member[:login])
            sleep 3
            #instance.find_elements(:css => '.content.active table [data-id]')[0].click
            instance.execute_script('$(".content.active  table [data-id] td").first().click()')
            modal_ready(browser: instance)
            #instance.find_elements(:css => 'label:contains(" ' + action[:name] + '")')[0].click
            instance.execute_script('$(".js-groupList tr:contains(\"' + data[:name] + '\") .js-groupListItem[value=' + member[:access] + ']").prop("checked", true)')
            screenshot(browser: instance, comment: 'group_create_member')
            instance.find_elements(css: '.modal button.js-submit')[0].click
            modal_disappear(browser: instance)
          }
        end
      end
      sleep 1
      return true
    }
    screenshot(browser: instance, comment: 'group_create_failed')
    raise 'group creation failed'
  end

=begin

  role_create(
    browser: browser2,
    data: {
      name: 'some role' + random,
      default_at_signup: false,
      permission: {
        'admin.group' => true,
        'preferences.password' => true,
      },
      member:    [
        'some_user_login',
      ],
    },
  )

=end

  def role_create(params = {})
    switch_window_focus(params)
    log('role_create', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    click(
      browser: instance,
      css:  'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css: '.content.active a[href="#manage/roles"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css: '.content.active a[data-type="new"]',
      mute_log: true,
    )
    modal_ready(browser: instance)
    element = instance.find_elements(css: '.modal input[name=name]')[0]
    element.clear
    element.send_keys(data[:name])

    if data.key?(:default_at_signup)
      element = instance.find_elements(css: '.modal select[name="default_at_signup"]')[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      if data[:default_at_signup] == true
        dropdown.select_by(:text, 'yes')
      else
        dropdown.select_by(:text, 'no')
      end
    end

    if data.key?(:permission)
      data[:permission].each { |permission_name, permission_value|
        if permission_value == false
          uncheck(
            browser: instance,
            css:     ".modal [data-permission-name=\"#{permission_name}\"]",
          )
        else
          check(
            browser: instance,
            css:     ".modal [data-permission-name=\"#{permission_name}\"]",
          )
        end
      }
    end

    instance.find_elements(css: '.modal button.js-submit')[0].click
    modal_disappear(browser: instance)
    11.times {
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert(true, 'role created')
        modal_disappear(browser: instance) # wait until modal has gone

        # add member
        if data[:member]
          data[:member].each { |login|
            instance.find_elements(css: 'a[href="#manage"]')[0].click
            sleep 1
            instance.find_elements(css: '.content.active a[href="#manage/users"]')[0].click
            sleep 3
            element = instance.find_elements(css: '.content.active  [name="search"]')[0]
            element.clear
            element.send_keys(login)
            sleep 3
            #instance.find_elements(:css => '.content.active table [data-id]')[0].click
            instance.execute_script('$(".content.active table [data-id] td").first().click()')
            sleep 3
            #instance.find_elements(:css => 'label:contains(" ' + action[:name] + '")')[0].click
            instance.execute_script('$(\'label:contains(" ' + data[:name] + '")\').first().click()')
            instance.find_elements(css: '.modal button.js-submit')[0].click
            modal_disappear(browser: instance)
          }
        end
      end
      sleep 1
      return true
    }
    screenshot(browser: instance, comment: 'role_create_failed')
    raise 'role creation failed'
  end

=begin

  role_create(
    browser: browser2,
    data: {
      name: 'some role' + random,
      default_at_signup: false,
      permission: {
        'admin.group' => true,
        'preferences.password' => true,
      },
      member:    [
        'some_user_login',
      ],
    },
  )

=end

  def role_edit(params = {})
    switch_window_focus(params)
    log('role_edit', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    click(
      browser: instance,
      css:  'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[href="#manage/roles"]',
      mute_log: true,
    )
    instance.execute_script('$(\'.content.active table tr td:contains(" ' + data[:name] + '")\').first().click()')

    modal_ready(browser: instance)
    element = instance.find_elements(css: '.modal input[name=name]')[0]
    element.clear
    element.send_keys(data[:name])

    if data.key?(:default_at_signup)
      element = instance.find_elements(css: '.modal select[name="default_at_signup"]')[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      if data[:default_at_signup] == true
        dropdown.select_by(:text, 'yes')
      else
        dropdown.select_by(:text, 'no')
      end
    end

    if data.key?(:permission)
      data[:permission].each { |permission_name, permission_value|
        if permission_value == false
          uncheck(
            browser: instance,
            css:     ".modal [data-permission-name=\"#{permission_name}\"]",
          )
        else
          check(
            browser: instance,
            css:     ".modal [data-permission-name=\"#{permission_name}\"]",
          )
        end
      }
    end

    if data.key?(:active)
      element = instance.find_elements(css: '.modal select[name="active"]')[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      if data[:active] == true
        dropdown.select_by(:text, 'active')
      else
        dropdown.select_by(:text, 'inactive')
      end
    end

    instance.find_elements(css: '.modal button.js-submit')[0].click
    modal_disappear(browser: instance)
    11.times {
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert(true, 'role created')
        modal_disappear(browser: instance) # wait until modal has gone

        # add member
        if data[:member]
          data[:member].each { |login|
            instance.find_elements(css: 'a[href="#manage"]')[0].click
            sleep 1
            instance.find_elements(css: '.content.active a[href="#manage/users"]')[0].click
            sleep 3
            element = instance.find_elements(css: '.content.active [name="search"]')[0]
            element.clear
            element.send_keys(login)
            sleep 3
            #instance.find_elements(:css => '.content.active table [data-id]')[0].click
            instance.execute_script('$(".content.active table [data-id] td").first().click()')
            sleep 3
            #instance.find_elements(:css => 'label:contains(" ' + action[:name] + '")')[0].click
            instance.execute_script('$(\'label:contains(" ' + data[:name] + '")\').first().click()')
            instance.find_elements(css: '.modal button.js-submit')[0].click
            modal_disappear(browser: instance)
          }
        end
      end
      sleep 1
      return true
    }
    screenshot(browser: instance, comment: 'role_edit_failed')
    raise 'role edit failed'
  end

=begin

  object_manager_attribute_create(
    browser: browser2,
    data: {
      name: 'field_name' + random,
      display: 'Display Name of Field',
      data_type: 'Select',
      data_option: {
        options: {
          'aa' => 'AA',
          'bb' => 'BB',
        },

        default: 'abc',
      },
    },
    error: 'already exists'
  )

  object_manager_attribute_create(
    browser: browser2,
    data: {
      name: 'field_name' + random,
      display: 'Display Name of Field',
      data_type: 'Text',
      data_option: {
        default: 'abc',
      },
    },
    error: 'already exists'
  )

  object_manager_attribute_create(
    browser: browser2,
    data: {
      name: 'field_name' + random,
      display: 'Display Name of Field',
      data_type: 'Integer',
      data_option: {
        default: '15',
        min: 1,
        max: 999999,
      },
    },
    error: 'already exists'
  )

  object_manager_attribute_create(
    browser: browser2,
    data: {
      name: 'field_name' + random,
      display: 'Display Name of Field',
      data_type: 'Datetime',
      data_option: {
        future: true,
        past: true,
        diff: 24,
      },
    },
    error: 'already exists'
  )

  object_manager_attribute_create(
    browser: browser2,
    data: {
      name: 'field_name' + random,
      display: 'Display Name of Field',
      data_type: 'Date',
      data_option: {
        future: true,
        past: true,
        diff: 24,
      },
    },
    error: 'already exists'
  )

  object_manager_attribute_create(
    browser: browser2,
    data: {
      name: 'field_name' + random,
      display: 'Display Name of Field',
      data_type: 'Boolean',
      data_option: {
        options: {
          true: 'YES',
          false: 'NO',
        }
        default: undefined,
      },
    },
    error: 'already exists'
  )

=end

  def object_manager_attribute_create(params = {})
    switch_window_focus(params)
    log('object_manager_attribute_create', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    click(
      browser: instance,
      css:  'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[href="#system/object_manager"]',
      mute_log: true,
    )
    sleep 4
    click(
      browser: instance,
      css:  '.content.active .js-new',
      mute_log: true,
    )
    modal_ready(browser: instance)
    element = instance.find_elements(css: '.modal input[name=name]')[0]
    element.clear
    element.send_keys(data[:name])
    element = instance.find_elements(css: '.modal input[name=display]')[0]
    element.clear
    element.send_keys(data[:display])
    select(
      browser:  instance,
      css:      '.modal select[name="data_type"]',
      value:    data[:data_type],
      mute_log: true,
    )
    if data[:data_option]
      if data[:data_option][:options]
        if data[:data_type] == 'Boolean'
          element = instance.find_elements(css: '.modal .js-valueTrue').first
          element.clear
          element.send_keys(data[:data_option][:options][:true])
          element = instance.find_elements(css: '.modal .js-valueFalse').first
          element.clear
          element.send_keys(data[:data_option][:options][:false])
        else
          data[:data_option][:options].each { |key, value|
            element = instance.find_elements(css: '.modal .js-Table .js-key').last
            element.clear
            element.send_keys(key)
            element = instance.find_elements(css: '.modal .js-Table .js-value').last
            element.clear
            element.send_keys(value)
            element = instance.find_elements(css: '.modal .js-Table .js-add')[0]
            element.click
          }
        end
      end

      [:default, :min, :max, :diff].each { |key|
        next if !data[:data_option].key?(key)
        element = instance.find_elements(css: ".modal [name=\"data_option::#{key}\"]").first
        element.clear
        element.send_keys(data[:data_option][key])
      }

      [:future, :past].each { |key|
        next if !data[:data_option].key?(key)
        select(
          browser:  instance,
          css:      ".modal select[name=\"data_option::#{key}\"]",
          value:    data[:data_option][key],
          mute_log: true,
        )
      }

    end
    instance.find_elements(css: '.modal button.js-submit')[0].click
    if params[:error]
      sleep 4
      watch_for(
        css: '.modal',
        value: params[:error],
      )
      click(
        browser: instance,
        css:  '.modal .js-close',
      )
      modal_disappear(browser: instance)
      return
    end

    11.times {
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert(true, 'object manager attribute created')
        sleep 1
        return true
      end
      sleep 1
    }
    screenshot(browser: instance, comment: 'object_manager_attribute_create_failed')
    raise 'object manager attribute creation failed'
  end

=begin

  object_manager_attribute_update(
    browser: browser2,
    data: {
      name: 'field_name' + random,
      display: 'Display Name of Field',
      data_type: 'Select',
      data_option: {
        options: {
          'aa' => 'AA',
          'bb' => 'BB',
        },

        default: 'abc',
      },
    },
    error: 'already exists'
  )

=end

  def object_manager_attribute_update(params = {})
    switch_window_focus(params)
    log('object_manager_attribute_update', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    click(
      browser: instance,
      css:  'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[href="#system/object_manager"]',
      mute_log: true,
    )
    sleep 4

    instance.execute_script("$(\".content.active td:contains('#{data[:name]}')\").first().click()")
    modal_ready(browser: instance)
    element = instance.find_elements(css: '.modal input[name=display]')[0]
    element.clear
    element.send_keys(data[:display])
    select(
      browser:  instance,
      css:      '.modal select[name="data_type"]',
      value:    data[:data_type],
      mute_log: true,
    )
    if data[:data_option]
      if data[:data_option][:options]
        if data[:data_type] == 'Boolean'
          element = instance.find_elements(css: '.modal .js-valueTrue').first
          element.clear
          element.send_keys(data[:data_option][:options][:true])
          element = instance.find_elements(css: '.modal .js-valueFalse').first
          element.clear
          element.send_keys(data[:data_option][:options][:false])
        else
          data[:data_option][:options].each { |key, value|
            element = instance.find_elements(css: '.modal .js-Table .js-key').last
            element.clear
            element.send_keys(key)
            element = instance.find_elements(css: '.modal .js-Table .js-value').last
            element.clear
            element.send_keys(value)
            element = instance.find_elements(css: '.modal .js-Table .js-add')[0]
            element.click
          }
        end
      end

      [:default, :min, :max, :diff].each { |key|
        next if !data[:data_option].key?(key)
        element = instance.find_elements(css: ".modal [name=\"data_option::#{key}\"]").first
        element.clear
        element.send_keys(data[:data_option][key])
      }

      [:future, :past].each { |key|
        next if !data[:data_option].key?(key)
        select(
          browser:  instance,
          css:      ".modal select[name=\"data_option::#{key}\"]",
          value:    data[:data_option][key],
          mute_log: true,
        )
      }

    end
    instance.find_elements(css: '.modal button.js-submit')[0].click
    if params[:error]
      sleep 4
      watch_for(
        css: '.modal',
        value: params[:error],
      )
      click(
        browser: instance,
        css:  '.modal .js-close',
      )
      modal_disappear(browser: instance)
      return
    end

    11.times {
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text =~ /#{Regexp.quote(data[:name])}/
        assert(true, 'object manager attribute updated')
        sleep 1
        return true
      end
      sleep 1
    }
    screenshot(browser: instance, comment: 'object_manager_attribute_update_failed')
    raise 'object manager attribute update failed'
  end

=begin

  object_manager_attribute_delete(
    browser: browser2,
    data: {
      name: 'field_name' + random,
    },
  )

=end

  def object_manager_attribute_delete(params = {})
    switch_window_focus(params)
    log('object_manager_attribute_delete', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    click(
      browser: instance,
      css: 'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css: '.content.active a[href="#system/object_manager"]',
      mute_log: true,
    )
    sleep 4

    instance = params[:browser] || @browser
    data     = params[:data]
    r = instance.execute_script("$(\".content.active td:contains('#{data[:name]}')\").first().closest('tr').find('.js-delete').click()")
    #p "rrr #{r.inspect}"
  end

=begin

  object_manager_attribute_discard_changes(
    browser: browser2,
  )

=end

  def object_manager_attribute_discard_changes(params = {})
    switch_window_focus(params)
    log('object_manager_attribute_discard_changes', params)

    instance = params[:browser] || @browser

    click(
      browser: instance,
      css:  'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[href="#system/object_manager"]',
      mute_log: true,
    )
    sleep 4

    element = instance.find_elements(css: '.content.active .js-discard').first
    element.click

    watch_for_disappear(
      browser: instance,
      css:     '.content.active .js-discard',
    )

  end

=begin

  tags_verify(
    browser: browser2,
    tags: {
      'tag 1' => true,
      'tag 2' => true,
      'tag 3' => false,
    },
  )

=end

  def tags_verify(params = {})
    switch_window_focus(params)
    log('tags_verify', params)

    instance = params[:browser] || @browser

    tags = instance.find_elements({ css: '.content.active .js-tag' })
    assert(tags)
    assert(tags[0])

    tags_found = {}
    params[:tags].each { |key, _value|
      tags_found[key] = false
    }

    tags.each { |element|
      text = element.text
      if tags_found.key?(text)
        tags_found[text] = true
      else
        assert(false, "tag exists but is not in check to verify '#{text}'")
      end
    }
    params[:tags].each { |key, value|
      assert_equal(value, tags_found[key], "tag '#{key}'")
    }
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

  def log(method, params = {})
    begin
      instance = params[:browser] || @browser
      if instance
        logs = instance.manage.logs.get(:browser)
        logs.each { |log|
          next if log.level == 'WARNING' && log.message =~ /Declaration\sdropped./ # ignore ff css warnings
          time = Time.zone.parse(Time.zone.at(log.timestamp / 1000).to_datetime.to_s)
          puts "#{time}/#{log.level}: #{log.message}"
        }
      end
    rescue
      # failed to get logs
    end
    return if !@@debug
    return if params[:mute_log]
    puts "#{Time.zone.now}/#{method}: #{params.inspect}"
  end
end
