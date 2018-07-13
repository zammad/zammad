ENV['RAILS_ENV'] = 'test'
# rubocop:disable HandleExceptions, NonLocalExitFromIterator, Style/GuardClause, Lint/MissingCopEnableDirective
require File.expand_path('../config/environment', __dir__)
require 'selenium-webdriver'
require 'json'
require 'net/http'
require 'uri'

class TestCase < Test::Unit::TestCase

  DEBUG = true

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
    if browser.match?(/(internet_explorer|ie)/i)
      return false
    end
    true
  end

  def browser_url
    ENV['BROWSER_URL'] || 'http://localhost:3000'
  end

  def browser_instance
    @browsers ||= {}
    if ENV['REMOTE_URL'].blank?
      local_browser = Selenium::WebDriver.for(browser.to_sym, profile: profile)
      @browsers[local_browser.hash] = local_browser
      browser_instance_preferences(local_browser)
      return local_browser
    end

    # avoid "Cannot read property 'get_Current' of undefined" issues
    (1..5).each do |count|
      begin
        local_browser = browser_instance_remote
        break
      rescue
        wait_until_ready = rand(5..13)
        sleep wait_until_ready
        log('browser_instance', { rescure: true, count: count, sleep: wait_until_ready })
      end
    end

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
    if !ENV['REMOTE_URL']&.match?(/saucelabs|(grid|ci)\.(zammad\.org|znuny\.com)/i)
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
    @browsers.each_value do |local_browser|
      screenshot(browser: local_browser, comment: 'teardown')
      browser_instance_close(local_browser)
    end
  end

  def screenshot(params = {})
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
    url:         'some url', # optional, in case of aleady opened brower a reload is done because url is called again
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

    5.times do
      sleep 1
      login = instance.find_elements(css: '#login')[0]

      next if !login
      assert(true, 'logout ok')
      return
    end
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
    if !current_url.match?(/#{Regexp.quote(params[:url])}/)
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
    css:     '.some_class',
    fast:    false, # do not wait
    wait:    1, # wait 1 sec.
  )

  click(
    browser: browser1,
    xpath:   '//a[contains(@class,".text-1")]',
    fast:    false, # do not wait
    wait:    1, # wait 1 sec.
  )

  click(
    browser: browser1,
    text:    '.partial_link_text',
    fast:    false, # do not wait
    wait:    1, # wait 1 sec.
  )

=end

  def click(params)
    switch_window_focus(params)
    log('click', params)

    instance = params[:browser] || @browser
    if params.include?(:css)
      param_key        = :css
      find_element_key = :css
    elsif params.include?(:xpath)
      param_key        = :xpath
      find_element_key = :xpath
    else
      param_key        = :text
      find_element_key = :partial_link_text
      sleep 0.5
    end

    begin
      elements = instance.find_elements(find_element_key => params[param_key])
                         .tap { |e| e.slice!(1..-1) unless params[:all] }

      if elements.empty?
        return if params[:only_if_exists] == true
        raise "No such element '#{params[param_key]}'"
      end

      # a clumsy substitute for elements.each(&:click)
      # (we need to refresh element references after each element.click
      # because if clicks alter page content,
      # subsequent element.clicks will raise a StaleElementReferenceError)
      elements.length.times do |i|
        instance.find_elements(find_element_key => params[param_key])[i].try(:click)
      end
    rescue => e
      raise e if (fail_count ||= 0).positive?

      fail_count += 1
      log('click', { rescure: true })
      sleep 0.5
      retry
    end

    sleep 0.2 if !params[:fast]
    sleep params[:wait] if params[:wait]
  end

=begin

  perform_macro('Close & Tag as Spam')

  # or

  perform_macro(
    name:    'Close & Tag as Spam',
    browser: browser1,
  )

=end

  def perform_macro(params)
    switch_window_focus(params)
    log('perform_macro', params)

    instance = params[:browser] || @browser

    click(
      browser: instance,
      css:     '.active.content .js-submitDropdown .js-openDropdownMacro'
    )

    click(
      browser: instance,
      xpath:   "//div[contains(@class, 'content') and contains(@class, 'active')]//li[contains(@class, 'js-dropdownActionMacro') and contains(text(), '#{params[:name]}')]"
    )
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
    sleep 0.3
    screenshot(browser: instance, comment: 'scroll_to_after')
  end

=begin

  modal_close(
    browser: browser1,
  )

=end

  def modal_close(params = {})
    switch_window_focus(params)
    log('modal_close', params)

    instance = params[:browser] || @browser

    element = instance.find_elements(css: '.modal .js-close')[0]
    raise "No such modal to close #{params.inspect}" if !element

    element.click
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
    sleep 3
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

    watch_for_disappear(
      browser: instance,
      css:     '.modal',
      timeout: params[:timeout] || 8,
    )
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
    displayed: true, # true|false
  )

=end

  def exists(params)
    retries ||= 0

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
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    sleep retries
    retries += 1
    retry if retries < 3
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

    element = instance.find_elements(css: params[:css])[0]
    if !params[:no_click]
      element.click
    end
    element.clear

    begin
      if !params[:slow]
        element.send_keys(params[:value])
      else
        element.send_keys('')
        keys = params[:value].to_s.split('')
        keys.each do |key|
          instance.action.send_keys(key).perform
        end
      end
    rescue => e
      sleep 0.5

      # just try again
      log('set', { rescure: true })
      element = instance.find_elements(css: params[:css])[0]
      raise "No such element '#{params[:css]}'" if !element
      if !params[:slow]
        element.send_keys(params[:value])
      else
        element.send_keys('')
        keys = params[:value].to_s.split('')
        keys.each do |key|
          instance.action.send_keys(key).perform
        end
      end
    end

    # it's not working stable with ff via selenium, use js
    if browser =~ /firefox/i && params[:css] =~ /\[data-name=/
      log('set_ff_trigger_workaround', params)
      instance.execute_script("$('#{params[:css]}').trigger('focusout')")
    end

    if params[:blur]
      instance.execute_script("$('#{params[:css]}').blur()")
    end

    sleep 0.2
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

    # searchable select
    element = instance.find_elements(css: "#{params[:css]}.js-shadow")[0]
    if element
      element = instance.find_elements(css: "#{params[:css]}.js-shadow + .js-input")[0]
      element.click
      element.clear
      sleep 0.2
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
    instance.execute_script("$('#{params[:css]}:not(:checked)').click()")
    #element = instance.find_elements(css: params[:css])[0]
    #checked = element.attribute('checked')
    #element.click if !checked
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

    instance.execute_script("$('#{params[:css]}:checked').click()")
    #element = instance.find_elements(css: params[:css])[0]
    #checked = element.attribute('checked')
    #element.click if checked
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
    if params[:value].class == Array
      params[:value].each do |key|
        if element
          element.send_keys(key)
        else
          instance.action.send_keys(key).perform
        end
      end
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

    if params[:css].match?(/select/)
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      success  = false
      dropdown.selected_options&.each do |option|
        if option.text == params[:value]
          success = true
        end
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
             elsif params[:css].match?(/(input|textarea)/i)
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
    elsif text.match?(/#{Regexp.quote(params[:value])}/i)
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

Get the on-screen pixel coordinates of a given DOM element. Can be used to compare
the relative location of table rows before and after sort, for example.

Returns a Selenium::WebDriver::Point object. Use result.x and result.y to access
its X and Y coordinates respectively.

      get_location(
        browser: browser1,
        css: '.some_class',
      )

=end

  def get_location(params)
    switch_window_focus(params)
    log('exists', params)

    instance = params[:browser] || @browser
    if params[:css]
      query = { css: params[:css] }
    end
    if params[:xpath]
      query = { xpath: params[:xpath] }
    end
    if !instance.find_elements(query)[0]
      screenshot(browser: instance, comment: 'exists_failed')
      raise "#{query} dosn't exist, but should"
    end

    instance.find_elements(query)[0].location
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
    cookies.each do |cookie|
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
    end
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
    if title.match?(/#{params[:value]}/i)
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
        if title.match?(/#{data[:title]}/i)
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

    element = instance.find_element(css: '#navigation').find_element(partial_link_text: data[:title])
    if !element
      screenshot(browser: instance, comment: 'open_task_failed')
      raise "no task with title '#{data[:title]}' found"
    end
    # firefix/marionette issue with Selenium::WebDriver::Error::ElementNotInteractableError: could not be scrolled into view
    # use js workaround instead of native click
    instance.execute_script("$('#navigation .tasks .task:contains(\"#{data[:title]}\") .nav-tab-name').click()")
    #element.click
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

    element = instance.find_element(css: '#navigation').find_element(partial_link_text: data[:title])
    if !element
      screenshot(browser: instance, comment: 'close_task_failed')
      raise "no task with title '#{data[:title]}' found"
    end

    instance.action.move_to(element).release.perform
    sleep 0.1
    instance.execute_script("$('#navigation .tasks .task:contains(\"#{data[:title]}\") .js-close').click()")

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
    files:   ['path/in/home/some_file.ext'], # 'test/data/pdf/test1.pdf'
  )

=end

  def file_upload(params = {})
    switch_window_focus(params)
    log('file_upload', params)

    instance = params[:browser] || @browser

    params[:files].each do |file|
      instance.find_elements(css: params[:css])[0].send_keys(Rails.root.join(file))
    end
    sleep 2 * params[:files].count
  end

=begin

  watch_for(
    browser:   browser1,
    container: element # optional, defaults to browser, must exist at the time of dispatch
    css:       '#content .text-1', # xpath or css required
    xpath:     '/content[contains(@class,".text-1")]', # xpath or css required
    value:     'some text',
    attribute: 'some_attribute' # optional
    timeout:   16, # in sec, default 16
  )

=end

  def watch_for(params = {})
    switch_window_focus(params)
    log('watch_for', params)

    browser = params[:browser] || @browser
    instance = params[:container] || browser

    selector = params[:css] || params[:xpath]
    selector_type = if params.key?(:css)
                      :css
                    elsif params.key?(:xpath)
                      :xpath
                    end

    timeout = 16
    if params[:timeout]
      timeout = params[:timeout]
    end
    loops = timeout.to_i * 2
    text = ''
    (1..loops).each do
      element = instance.find_elements(selector_type => selector)[0]
      if element #&& element.displayed?
        begin
          # watch for selector
          if !params[:attribute] && !params[:value]
            assert(true, "'#{selector}' found")
            sleep 0.5
            return true

          # match an attribute
          else
            text = if params[:attribute]
                     element.attribute(params[:attribute])
                   elsif selector.match?(/(input|textarea)/i)
                     element.attribute('value')
                   else
                     element.text
                   end
            if text.match?(/#{params[:value]}/i)
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
    end
    screenshot(browser: browser, comment: 'watch_for_failed')
    if !params[:attribute] && !params[:value]
      raise "'#{selector}' not found"
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
    (1..loops).each do
      element = instance.find_elements(css: params[:css])[0]
      if !element #|| element.displayed?
        assert(true, 'not found')
        sleep 1
        return true
      end
      if params[:value]
        begin
          text = instance.find_elements(css: params[:css])[0].text
          if !text.match?(/#{params[:value]}/i)
            assert(true, "not matching '#{params[:value]}' in text '#{text}'")
            sleep 1
            return true
          end
        rescue
          # try again
        end
      end
      sleep 1
    end
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
        if instance.find_elements(css: '#navigation .tasks .task:first-child')[0]
          instance.action.move_to(instance.find_elements(css: '#navigation .tasks .task:first-child')[0]).release.perform
          click_element = instance.find_elements(css: '#navigation .tasks .task:first-child .js-close')[0]
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
      instance.action.move_to(element).release.perform
      sleep 0.1
      instance.execute_script("$('.js-notificationsContainer .js-items .js-item .activity-text:contains(\"#{data[:title]}\") .js-remove').first().click()")

    else
      css = ".js-notificationsContainer .js-items .js-item:nth-child(#{data[:position]})"
      element = instance.find_elements(css: css)[0]
      if !element
        screenshot(browser: instance, comment: 'close_online_notitifcation')
        raise "no online notification with postion '#{css}' found"
      end

      instance.action.move_to(element).release.perform
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
          instance.action.move_to(instance.find_elements(css: '.js-notificationsContainer .js-item:first-child')[0]).perform
          sleep 0.1
          click_element = instance.find_elements(css: '.js-notificationsContainer .js-item:first-child .js-remove')[0]
          click_element&.click
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
      data[:roles].each do |role|
        instance.execute_script("$(\".modal [data-name=role_ids] .js-pool .js-option:not(.is-hidden):contains('#{role}')\").first().click()")
      end
    end

    data[:selector]&.each do |key, value|
      select(
        browser:  instance,
        css:      '.modal .ticket_selector .js-attributeSelector select',
        value:    key,
        mute_log: true,
      )
      sleep 0.5
      if data.key?('text_input')
        set(
          browser:  instance,
          css:      '.modal .ticket_selector .js-value input',
          value:    value,
          mute_log: true,
        )
      else
        select(
          browser:      instance,
          css:          '.modal .ticket_selector .js-value select',
          value:        value,
          deselect_all: true,
          mute_log:     true,
        )
      end
    end

    if data['order::direction']
      select(
        browser:  instance,
        css:      '.modal select[name="order::direction"]',
        value:    data['order::direction'],
        mute_log: true,
      )
    end

    if data[:group_by]
      select(
        browser:  instance,
        css:      '.modal select[name="group_by"]',
        value:    data[:group_by],
        mute_log: true,
      )
    end

    if data[:group_direction]
      select(
        browser:  instance,
        css:      '.modal select[name="group_direction"]',
        value:    data[:group_direction],
        mute_log: true,
      )
    end

    instance.find_elements(css: '.modal button.js-submit')[0].click
    modal_disappear(browser: instance)
    11.times do
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text.match?(/#{Regexp.quote(data[:name])}/)
        assert(true, 'overview created')
        overview = {
          name: name,
        }
        sleep 1
        return overview
      end
      sleep 1
    end
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
      data[:roles].each do |role|
        instance.execute_script("$(\".modal [data-name=role_ids] .js-pool .js-option:not(.is-hidden):contains('#{role}')\").first().click()")
      end
    end

    data[:selector]&.each do |key, value|
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
    end

    if data['order::direction']
      select(
        browser:  instance,
        css:      '.modal select[name="order::direction"]',
        value:    data['order::direction'],
        mute_log: true,
      )
    end

    if data[:group_direction]
      select(
        browser:  instance,
        css:      '.modal select[name="group_direction"]',
        value:    data[:group_direction],
        mute_log: true,
      )
    end

    instance.find_elements(css: '.modal button.js-submit')[0].click
    modal_disappear(browser: instance)
    11.times do
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text.match?(/#{Regexp.quote(data[:name])}/)
        assert(true, 'overview updated')
        overview = {
          name: name,
        }
        sleep 1
        return overview
      end
      sleep 1
    end
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
    custom_data_date: {
      key!: '02/28/2018',
    }
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
      only_if_exists: true,
    )
    click(
      browser: instance,
      css: 'a[href="#ticket/create"]',
      mute_log: true,
    )

    found = false
    7.times do
      element = instance.find_elements(css: '.content.active .newTicket')[0]
      if element
        found = true
        break
      end
      sleep 1
    end
    if !found
      screenshot(browser: instance, comment: 'ticket_create_failed')
      raise 'no ticket create screen found!'
    end

    if data[:group]
      if data[:group] == '-NONE-'

        # check if owner selection exists
        count = instance.find_elements(css: '.content.active .newTicket select[name="group_id"] option').count
        if count.nonzero?
          instance.find_elements(css: '.content.active .newTicket select[name="group_id"] option').each do |element|
            log('ticket_create invalid group count', text: element.text)
          end
        end
        assert_equal(0, count, 'owner selection should not be showm')

        # check count of agents, should be only 3 / - selection + master + agent on init screen
        count = instance.find_elements(css: '.content.active .newTicket select[name="owner_id"] option').count
        if count != 3
          instance.find_elements(css: '.content.active .newTicket select[name="owner_id"] option').each do |element|
            log('ticket_create invalid owner count', text: element.text)
          end
        end
        assert_equal(3, count, 'check if owner selection is - selection + master + agent per default')
      else

        # check count of agents, should be only 1 / - selection on init screen
        if !params[:disable_group_check]
          count = instance.find_elements(css: '.content.active .newTicket select[name="owner_id"] option').count
          if count != 1
            instance.find_elements(css: '.content.active .newTicket select[name="owner_id"] option').each do |element|
              log('ticket_create invalid owner count', text: element.text)
            end
          end
          assert_equal(1, count, 'check if owner selection is empty per default')
        end
        select(
          browser:  instance,
          css:      '.content.active .newTicket select[name="group_id"]',
          value:    data[:group],
          mute_log: true,
        )
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
      sleep 0.2
      # ff issue, sometimes enter event gets dropped
      # take user manually
      if instance.find_elements(css: '.content.active .newTicket .js-recipientDropdown.open')[0]
        instance.find_elements(css: '.content.active .newTicket .recipientList-entry.js-object.is-active')[0].click
        sleep 0.4
      end
    end

    params[:custom_data_select]&.each do |local_key, local_value|
      select(
        browser: instance,
        css:     ".content.active .newTicket select[name=\"#{local_key}\"]",
        value:   local_value,
      )
    end
    params[:custom_data_input]&.each do |local_key, local_value|
      set(
        browser: instance,
        css:     ".content.active .newTicket input[name=\"#{local_key}\"]",
        value:   local_value,
        clear:   true,
      )
    end
    params[:custom_data_date]&.each do |local_key, local_value|
      set(
        browser: instance,
        css:     ".content.active .newTicket div[data-name=\"#{local_key}\"] input[data-item=\"date\"]",
        value:   local_value,
        clear:   true,
      )
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

    #instance.execute_script('$(".content.active .newTicket form").submit();')
    click(
      browser: instance,
      css:  '.content.active .newTicket button.js-submit',
      mute_log: true,
    )

    sleep 1
    9.times do
      if instance.current_url.match?(/#{Regexp.quote('#ticket/zoom/')}/)
        assert(true, 'ticket created')
        sleep 2
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
          sleep 2 # wait until notify is gone
          return ticket
        end
      end
      sleep 1
    end
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
    custom_data_date: {
      key1: '02/21/2018',
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

    if data[:files]
      file_upload(
        css:   '.content.active .attachmentPlaceholder-inputHolder input',
        files: data[:files],
      )
    end

    params[:custom_data_select]&.each do |local_key, local_value|
      select(
        browser: instance,
        css:     ".active .sidebar select[name=\"#{local_key}\"]",
        value:   local_value,
      )
    end
    params[:custom_data_input]&.each do |local_key, local_value|
      set(
        browser: instance,
        css:     ".active .sidebar input[name=\"#{local_key}\"]",
        value:   local_value,
        clear:   true,
      )
    end
    params[:custom_data_date]&.each do |local_key, local_value|
      click(
        browser:  instance,
        css:      ".active .sidebar div[data-name=\"#{local_key}\"] input[data-item=\"date\"]",
        mute_log: true,
      )
      # weird bug where you cannot "clear" for date/time input
      # this is specific chrome problem, chrome bug report: https://bugs.chromium.org/p/chromedriver/issues/detail?id=1319#c2
      # indirect issue: https://github.com/angular/protractor/issues/562#issuecomment-47745263
      11.times do
        sendkey(
          value: :backspace,
        )
      end
      set(
        browser: instance,
        css:     ".active .sidebar div[data-name=\"#{local_key}\"] input[data-item=\"date\"]",
        value:   local_value,
      )
    end

    if data[:state] || data[:group] || data[:body] || params[:custom_data_select].present? || params[:custom_data_input].present?
      found = nil
      9.times do

        break if found

        begin
          text = instance.find_elements(css: '.content.active .js-reset')[0].text
          if text.match?(/(Discard your unsaved changes.|Verwerfen der)/)
            found = true
          end
        rescue
          # try again
        end
        sleep 1
      end
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
      return
    end

    9.times do
      begin
        text = instance.find_elements(css: '.content.active .js-reset')[0].text
        if text.blank?
          sleep 1
          return true
        end
      rescue
        # try again
      end
      sleep 1
    end
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
      if title.match?(/#{data[:title]}/i)
        assert(true, "matching '#{data[:title]}' in title '#{title}'")
      else
        raise "not matching '#{data[:title]}' in title '#{title}'"
      end
    end

    if data[:body]
      body = instance.find_elements(css: '.content.active [data-name="body"]').first.text.strip
      if body.match?(/#{data[:body]}/i)
        assert(true, "matching '#{data[:body]}' in body '#{body}'")
      else
        raise "not matching '#{data[:body]}' in body '#{body}'"
      end
    end

    params[:custom_data_select]&.each do |local_key, local_value|
      element = instance.find_elements(css: ".active .sidebar select[name=\"#{local_key}\"] option[selected]").first
      value = element.text.strip
      if value.match?(/#{local_value}/i)
        assert(true, "matching '#{value}' in #{local_key} '#{local_value}'")
      else
        raise "not matching '#{value}' in #{local_key} '#{local_value}'"
      end
    end
    params[:custom_data_input]&.each do |local_key, local_value|
      element = instance.find_elements(css: ".active .sidebar input[name=\"#{local_key}\"]").first
      value = element.text.strip
      if value.match?(/#{local_value}/i)
        assert(true, "matching '#{value}' in #{local_key} '#{local_value}'")
      else
        raise "not matching '#{value}' in #{local_key} '#{local_value}'"
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
    sleep 0.5
    execute(
      browser: instance,
      js: '$(".content.active .sidebar").css("display", "block")',
    )
    instance.find_elements(css: ".content.active .sidebar a[href=\"#{params[:link]}\"]")[0].click
    sleep 0.5
    execute(
      browser: instance,
      js: '$(".content.active .sidebar").css("display", "none")',
    )
    if params[:title]
      element = instance.find_element(css: '.content.active').find_element(partial_link_text: params[:title])
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
    if !number.match?(/#{params[:number]}/)
      screenshot(browser: instance, comment: 'ticket_open_by_overview_open_failed_failed')
      raise "unable to open ticket #{params[:number]}!"
    end
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
    #instance.find_element(partial_link_text: params[:number] } ).click
    instance.execute_script("$(\".js-global-search-result a:contains('#{params[:number]}') .nav-tab-icon\").first().click()")
    sleep 1
    number = instance.find_elements(css: '.content.active .ticketZoom-header .ticket-number')[0].text
    if !number.match?(/#{params[:number]}/)
      screenshot(browser: instance, comment: 'ticket_open_by_search_failed')
      raise "unable to search/find ticket #{params[:number]}!"
    end
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
    #instance.find_element(partial_link_text: params[:title] } ).click
    instance.execute_script("$(\".js-global-search-result a:contains('#{params[:title]}') .nav-tab-icon\").click()")
    sleep 1
    title = instance.find_elements(css: '.content.active .ticketZoom-header .js-objectTitle')[0].text
    if !title.match?(/#{params[:title]}/)
      screenshot(browser: instance, comment: 'ticket_open_by_title_failed')
      raise "unable to search/find ticket #{params[:title]}!"
    end
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
    instance.find_elements(css: '.content.active .sidebar a[href]').each do |element|
      url = element.attribute('href')
      url.gsub!(%r{(http|https)://.+?/(.+?)$}, '\\2')
      overviews[url] = 0
      #puts url.inspect
      #puts element.inspect
    end
    overviews.each_key do |url|
      count          = instance.find_elements(css: ".content.active .sidebar a[href=\"#{url}\"] .badge")[0].text
      overviews[url] = count.to_i
    end
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
    if !name.match?(/#{params[:value]}/)
      screenshot(browser: instance, comment: 'organization_open_by_search_failed')
      raise "unable to search/find org #{params[:value]}!"
    end
    assert(true, "org #{params[:value]} found")
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

    #instance.find_element(partial_link_text: params[:value]).click
    instance.execute_script("$(\".js-global-search-result a:contains('#{params[:value]}') .nav-tab-icon\").click()")
    sleep 1
    name = instance.find_elements(css: '.content.active h1')[0].text
    if !name.match?(/#{params[:value]}/)
      screenshot(browser: instance, comment: 'user_open_by_search_failed')
      raise "unable to search/find user #{params[:value]}!"
    end
    assert(true, "user #{params[:term]} found")
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
    if data[:organization]
      element = instance.find_elements(css: '.modal input.searchableSelect-main')[0]
      element.clear
      element.send_keys(data[:organization])

      begin
        retries ||= 0
        target    = nil
        until target
          sleep 0.5
          target = instance.find_elements(css: ".modal li[title='#{data[:organization]}']")[0]
        end
        target.click()
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
        sleep retries
        retries += 1
        retry if retries < 3
      end
    end
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

  organization_create(
    browser: browser2,
    data: {
      name: 'Test Organization',
    }
  )

=end

  def organization_create(params = {})
    switch_window_focus(params)
    log('organization_create', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    click(
      browser: instance,
      css:  'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[href="#manage/organizations"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[data-type="new"]',
      mute_log: true,
    )
    modal_ready(browser: instance)
    element = instance.find_elements(css: '.modal input[name=name]')[0]
    element.clear
    element.send_keys(data[:name])

    instance.find_elements(css: '.modal button.js-submit')[0].click
    modal_disappear(
      browser: instance,
      timeout: 5,
    )
    watch_for(
      browser: instance,
      css: 'body',
      value: data[:name],
    )
  end

=begin

  calendar_create(
    browser: browser2,
    data: {
       name: 'some calendar' + random,
       first_response_time_in_text: 61
    },
  )

=end

  def calendar_create(params = {})
    switch_window_focus(params)
    log('calendar_create', params)

    instance = params[:browser] || @browser
    data     = params[:data]

    click(
      browser: instance,
      css:  'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[href="#manage/calendars"]',
      mute_log: true,
    )
    sleep 4
    click(
      browser: instance,
      css:  '.content.active a.js-new',
      mute_log: true,
    )
    modal_ready(browser: instance)
    element = instance.find_elements(css: '.content.active .modal input[name=name]')[0]
    element.clear
    element.send_keys(data[:name])
    element = instance.find_elements(css: '.content.active .modal .js-input')[0]
    element.clear
    element.send_keys(data[:timezone])
    element.send_keys(:enter)
    instance.find_elements(css: '.modal button.js-submit')[0].click
    modal_disappear(browser: instance)
    7.times do
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text.match?(/#{Regexp.quote(data[:name])}/)
        assert(true, 'calendar created')
        sleep 1
        return true
      end
      sleep 1
    end
    screenshot(browser: instance, comment: 'calendar_create_failed')
    raise 'calendar creation failed'
  end

=begin

  sla_create(
    browser: browser2,
    data: {
       name: 'some sla' + random,
       calendar: 'some calendar name',
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
    if data[:calendar].present?
      element = instance.find_elements(css: '.modal select[name="calendar_id"]')[0]
      dropdown = Selenium::WebDriver::Support::Select.new(element)
      dropdown.select_by(:text, data[:calendar])
    end
    element = instance.find_elements(css: '.modal input[name=first_response_time_in_text]')[0]
    element.clear
    element.send_keys(data[:first_response_time_in_text])
    instance.find_elements(css: '.modal button.js-submit')[0].click
    modal_disappear(browser: instance)
    7.times do
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text.match?(/#{Regexp.quote(data[:name])}/)
        assert(true, 'sla created')
        sleep 1
        return true
      end
      sleep 1
    end
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
    7.times do
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text.match?(/#{Regexp.quote(data[:name])}/)
        assert(true, 'text module created')
        sleep 1
        return true
      end
      sleep 1
    end
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
    11.times do
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text.match?(/#{Regexp.quote(data[:name])}/)
        assert(true, 'signature created')
        sleep 1
        return true
      end
      sleep 1
    end
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
    11.times do
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text.match?(/#{Regexp.quote(data[:name])}/)
        assert(true, 'group created')
        modal_disappear(browser: instance) # wait until modal has gone

        # add member
        data[:member]&.each do |member|
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
          instance.find_elements(css: '.modal button.js-submit')[0].click
          modal_disappear(browser: instance)
        end
      end
      sleep 1
      return true
    end
    screenshot(browser: instance, comment: 'group_create_failed')
    raise 'group creation failed'
  end

=begin

  macro_create(
    browser:         browser1,
    name:            'Emmanuel Macro',
    ux_flow_next_up: 'Stay on tab',    # possible: 'Stay on tab', 'Close tab', 'Advance to next ticket from overview'
    actions: {
      'Tags' => {                      # currently only 'Tags' is supported
        operator: 'add',
        value:    'spam',
      }
    }
  )

=end

  def macro_create(params)
    switch_window_focus(params)
    log('macro_create', params)

    instance = params[:browser] || @browser

    click(
      browser: instance,
      css:     'a[href="#manage"]',
      mute_log: true,
    )

    click(
      browser: instance,
      css:     '.sidebar a[href="#manage/macros"]',
      mute_log: true,
    )

    click(
      browser: instance,
      css:     '.page-header-meta > a[data-type="new"]'
    )

    sendkey(
      browser: instance,
      css:     '.modal-body input[name="name"]',
      value:   params[:name]
    )

    params[:actions]&.each do |attribute, changes|

      select(
        browser:  instance,
        css:      '.modal .ticket_perform_action .js-filterElement .js-attributeSelector select',
        value:    attribute,
        mute_log: true,
      )

      next if attribute != 'Tags'

      select(
        browser:  instance,
        css:      '.modal .ticket_perform_action .js-filterElement .js-operator select',
        value:    changes[:operator],
        mute_log: true,
      )

      sendkey(
        browser:  instance,
        css:      '.modal .ticket_perform_action .js-filterElement .js-value .token-input',
        value:    changes[:value],
        mute_log: true,
      )
      sendkey(
        browser: instance,
        value:   :enter,
      )
    end

    select(
      browser: instance,
      css:     '.modal-body select[name="ux_flow_next_up"]',
      value:   params[:ux_flow_next_up]
    )

    click(
      browser: instance,
      css:     '.modal-footer button[type="submit"]'
    )

    watch_for(
      browser: instance,
      css:     'body',
      value:   params[:name],
    )

    assert(true, 'macro created')
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
      data[:permission].each do |permission_name, permission_value|
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
      end
    end

    instance.find_elements(css: '.modal button.js-submit')[0].click
    modal_disappear(browser: instance)
    11.times do
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text.match?(/#{Regexp.quote(data[:name])}/)
        assert(true, 'role created')
        modal_disappear(browser: instance) # wait until modal has gone

        # add member
        data[:member]&.each do |login|
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
        end
      end
      sleep 1
      return true
    end
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
      data[:permission].each do |permission_name, permission_value|
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
      end
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
    11.times do
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text.match?(/#{Regexp.quote(data[:name])}/)
        assert(true, 'role created')
        modal_disappear(browser: instance) # wait until modal has gone

        # add member
        data[:member]&.each do |login|
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
        end
      end
      sleep 1
      return true
    end
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
      browser:  instance,
      css:      'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser:  instance,
      css:      '.content.active a[href="#system/object_manager"]',
      mute_log: true,
    )
    watch_for(
      browser: instance,
      css:     '.content.active .js-new',
    )
    click(
      browser:  instance,
      css:      '.content.active .js-new',
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
          # rubocop:disable Lint/BooleanSymbol
          element = instance.find_elements(css: '.modal .js-valueTrue').first
          element.clear
          element.send_keys(data[:data_option][:options][:true])
          element = instance.find_elements(css: '.modal .js-valueFalse').first
          element.clear
          element.send_keys(data[:data_option][:options][:false])
          # rubocop:enable Lint/BooleanSymbol
        elsif data[:data_type] == 'Tree Select'
          add_tree_options(
            instance: instance,
            options:  data[:data_option][:options],
          )
        else
          data[:data_option][:options].each do |key, value|
            element = instance.find_elements(css: '.modal .js-Table .js-key').last
            element.clear
            element.send_keys(key)
            element = instance.find_elements(css: '.modal .js-Table .js-value').last
            element.clear
            element.send_keys(value)
            element = instance.find_elements(css: '.modal .js-Table .js-add')[0]
            element.click
          end
        end
      end

      %i[default min max diff].each do |key|
        next if !data[:data_option].key?(key)
        element = instance.find_elements(css: ".modal [name=\"data_option::#{key}\"]").first
        element.clear
        element.send_keys(data[:data_option][key])
      end

      %i[future past].each do |key|
        next if !data[:data_option].key?(key)
        select(
          browser:  instance,
          css:      ".modal select[name=\"data_option::#{key}\"]",
          value:    data[:data_option][key],
          mute_log: true,
        )
      end

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

    11.times do
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text.match?(/#{Regexp.quote(data[:name])}/)
        assert(true, 'object manager attribute created')
        sleep 1
        return true
      end
      sleep 1
    end
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
      browser:  instance,
      css:      'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser:  instance,
      css:      '.content.active a[href="#system/object_manager"]',
      mute_log: true,
    )
    watch_for(
      browser: instance,
      css:     '.content.active .js-new',
    )
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

    # if attribute is created, do not be able to select other types anymore
    if instance.find_elements(css: '.modal select[name="data_type"] option').count > 1
      assert(false, 'able to change the data_type of existing attribute which should not be allowed')
    end

    if data[:data_option]
      if data[:data_option][:options]
        if data[:data_type] == 'Boolean'
          # rubocop:disable Lint/BooleanSymbol
          element = instance.find_elements(css: '.modal .js-valueTrue').first
          element.clear
          element.send_keys(data[:data_option][:options][:true])
          element = instance.find_elements(css: '.modal .js-valueFalse').first
          element.clear
          element.send_keys(data[:data_option][:options][:false])
          # rubocop:enable Lint/BooleanSymbol
        else
          data[:data_option][:options].each do |key, value|
            element = instance.find_elements(css: '.modal .js-Table .js-key').last
            element.clear
            element.send_keys(key)
            element = instance.find_elements(css: '.modal .js-Table .js-value').last
            element.clear
            element.send_keys(value)
            element = instance.find_elements(css: '.modal .js-Table .js-add')[0]
            element.click
          end
        end
      end

      %i[default min max diff].each do |key|
        next if !data[:data_option].key?(key)
        element = instance.find_elements(css: ".modal [name=\"data_option::#{key}\"]").first
        element.clear
        element.send_keys(data[:data_option][key])
      end

      %i[future past].each do |key|
        next if !data[:data_option].key?(key)
        select(
          browser:  instance,
          css:      ".modal select[name=\"data_option::#{key}\"]",
          value:    data[:data_option][key],
          mute_log: true,
        )
      end

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

    11.times do
      element = instance.find_elements(css: 'body')[0]
      text = element.text
      if text.match?(/#{Regexp.quote(data[:name])}/)
        assert(true, 'object manager attribute updated')
        sleep 1
        return true
      end
      sleep 1
    end
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
    params[:tags].each_key do |key|
      tags_found[key] = false
    end

    tags.each do |element|
      text = element.text
      if tags_found.key?(text)
        tags_found[text] = true
      else
        assert(false, "tag exists but is not in check to verify '#{text}'")
      end
    end
    params[:tags].each do |key, value|
      assert_equal(value, tags_found[key], "tag '#{key}'")
    end
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
        logs.each do |log|
          next if log.level == 'WARNING' && log.message =~ /Declaration\sdropped./ # ignore ff css warnings
          time = Time.zone.parse(Time.zone.at(log.timestamp / 1000).to_datetime.to_s)
          puts "#{time}/#{log.level}: #{log.message}"
        end
      end
    rescue
      # failed to get logs
    end
    return if !DEBUG
    return if params[:mute_log]
    puts "#{Time.zone.now}/#{method}: #{params.inspect}"
  end

  private

  def add_tree_options(instance:, options:)

    # first level entries have to get added in regular order
    options.each_key.with_index do |option, index|

      if index != 0
        element = instance.find_elements(css: '.modal .js-treeTable .js-addRow')[index - 1]
        element.click
      end

      element = instance.find_elements(css: '.modal .js-treeTable .js-key')[index]
      element.clear
      element.send_keys(option)
    end

    add_sub_tree_recursion(
      instance: instance,
      options: options,
    )
  end

  def add_sub_tree_recursion(instance:, options:, offset: 0)
    options.each_value.inject(offset) do |child_offset, children|

      child_offset += 1

      # put your recursion glasses on 8-)
      add_sub_tree_options(
        instance: instance,
        options:  children,
        offset:   child_offset,
      )
    end
  end

  def add_sub_tree_options(instance:, options:, offset:)

    # sub level entries have to get added in reversed order
    level_options = options.to_a.reverse.to_h.keys

    level_options.each do |option|

      # sub level entries have to get added via 'add child row' link
      click_index = offset - 1

      element = instance.find_elements(css: '.modal .js-treeTable .js-addChild')[click_index]
      element.click

      element = instance.find_elements(css: '.modal .js-treeTable .js-key')[offset]
      element.clear
      element.send_keys(option)
      sleep 0.25
    end

    add_sub_tree_recursion(
      instance: instance,
      options:  options,
      offset:   offset,
    )
  end

  def token_verify(css, value)
    original_element = @browser.find_element(:css, css)
    elem = original_element.find_element(xpath: '../input[contains(@class, "token-input")]')
    elem.send_keys value
    elem.send_keys :enter

    watch_for(
      xpath: '../*/span[contains(@class,"token-label")]',
      value: value,
      container: original_element
    )
  end

  def toggle_checkbox(scope, value)
    checkbox = scope.find_element(css: "input[value=#{value}]")

    @browser
      .action
      .move_to(checkbox)
      .click
      .perform
  end

  def checkbox_is_selected(scope, value)
    scope.find_element(css: "input[value=#{value}]").property('checked')
  end

=begin

  Retrieve a hash of all the avaiable Zammad settings and their current values.

  settings = fetch_settings()

=end

  def fetch_settings
    url = URI.parse(browser_url)
    req = Net::HTTP::Get.new(browser_url + '/api/v1/settings/')
    req.basic_auth('master@example.com', 'test')

    res = Net::HTTP.start(url.host, url.port) do |http|
      http.request(req)
    end
    raise "HTTP error #{res.code} while fetching #{browser_url}/api/v1/settings/" if res.code != '200'
    JSON.parse(res.body)
  end

=begin

  Enable or disable Zammad experiemental features remotely.

  set_setting('ui_ticket_zoom_attachments_preview', true)

=end

  def set_setting(name, value)
    name_to_id = fetch_settings.map { |s| [s['name'], s['id']] }.to_h
    id = name_to_id[name]

    url = URI.parse(browser_url)
    req = Net::HTTP::Put.new("#{browser_url}/api/v1/settings/#{id}")
    req['Content-Type'] = 'application/json'
    req.basic_auth('master@example.com', 'test')
    req.body = { 'state_current' => { 'value' => value } }.to_json
    res = Net::HTTP.start(url.host, url.port) do |http|
      http.request(req)
    end
    raise "HTTP error #{res.code} while POSTing to #{browser_url}/api/v1/settings/" if res.code != '200'
  end
end
