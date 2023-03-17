# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module CommonActions

  delegate :app_host, to: Capybara

  # Performs a login with the given credentials and closes the clues (if present).
  # The 'remember me' can optionally be checked.
  #
  # @example
  #  login(
  #    username: 'admin@example.com',
  #    password: 'test',
  #  )
  #
  # @example
  #  login(
  #    username:    'admin@example.com',
  #    password:    'test',
  #    remember_me: true,
  #  )
  #
  # return [nil]
  def login(username:, password:, remember_me: false, app: self.class.metadata[:app])
    ENV['FAKE_SELENIUM_LOGIN_USER_ID'] = nil
    ENV['FAKE_SELENIUM_LOGIN_PENDING'] = nil

    if !page.current_path || page.current_path.exclude?('login')
      visit '/', skip_waiting: true, app: app
    end

    case app
    when :mobile
      wait_for_test_flag('applicationLoaded.loaded', skip_clearing: true)

      within('#signin') do
        find_input('Username / Email').type(username)
        find_input('Password').type(password)

        find_toggle('Remember me').toggle_on if remember_me

        click_button
      end

      wait_for_test_flag('useSessionUserStore.getCurrentUser.loaded', skip_clearing: true)
    else
      within('#login') do
        fill_in 'username', with: username
        fill_in 'password', with: password

        # check via label because checkbox is hidden
        click('.checkbox-replacement') if remember_me

        # submit
        click_button
      end

      current_login
      await_empty_ajax_queue
    end
  end

  # Checks if the current session is logged in.
  #
  # @example
  #  logged_in?
  # => true
  #
  # @return [true, false]
  def logged_in?
    current_login.present?
  rescue Capybara::ElementNotFound
    false
  end

  # Returns the login of the currently logged in user.
  #
  # @example
  #  current_login
  # => 'admin@example.com'
  #
  # @return [String] the login of the currently logged in user.
  def current_login
    find('.user-menu .user a')[:title]
  end

  # Returns the User record for the currently logged in user.
  #
  # @example
  #  current_user.login
  # => 'admin@example.com'
  #
  # @example
  #  current_user do |user|
  #    user.group_names_access_map = group_names_access_map
  #    user.save!
  #  end
  #
  # @return [User] the current user record.
  def current_user
    ::User.find_by(login: current_login).tap do |user|
      yield user if block_given?
    end
  end

  # Logs out the currently logged in user.
  #
  # @example
  #  logout
  #
  def logout(app: self.class.metadata[:app])
    ENV['FAKE_SELENIUM_LOGIN_USER_ID'] = nil
    ENV['FAKE_SELENIUM_LOGIN_PENDING'] = nil

    visit('logout')

    case app
    when :mobile
      wait_for_test_flag('logout.success', skip_clearing: true)
    else
      wait.until_disappears { find('.user-menu .user a', wait: false) }
    end
  end

  # Overwrites the Capybara::Session#visit method to allow SPA navigation
  # and visiting of external URLs.
  # All routes not starting with `/` will be handled as SPA routes.
  # All routes containing `://` will be handled as an external URL.
  #
  # @see Capybara::Session#visit
  #
  # @example
  #  visit('logout')
  # => visited SPA route 'localhost:32435/#logout'
  #
  # @example
  #  visit('/test/ui')
  # => visited regular route 'localhost:32435/test/ui'
  #
  # @example
  #  visit('https://zammad.org')
  # => visited external URL 'https://zammad.org'
  #
  def visit(route, app: self.class.metadata[:app], skip_waiting: false)
    if route.include?('://')
      return without_port do
        super(route)
      end
    elsif !route.start_with?('/')
      route = if app == :mobile || route.start_with?('#')
                "/#{route}"
              else
                "/##{route}"
              end
    end

    if app == :mobile
      route = "/mobile#{route}"
    end

    super(route)

    wait_for_loading_to_complete(route: route, app: app, skip_waiting: skip_waiting)
  end

  def wait_for_loading_to_complete(route:, app: self.class.metadata[:app], skip_waiting: false)
    case app
    when :mobile
      return if skip_waiting

      wait_for_test_flag('applicationLoaded.loaded', skip_clearing: true)
    else
      return if route && (!route.start_with?('/#') || route == '/#logout')

      wait_for_pending_login(skip_waiting)

      # make sure all AJAX requests are done
      await_empty_ajax_queue

      # make sure loading is completed (e.g. ticket zoom may take longer)
      expect(page).to have_no_css('.icon-loading', wait: 30) if !skip_waiting
    end
  end

  # Overwrites the global Capybara.always_include_port setting (true)
  # with false. This comes in handy when visiting external pages.
  #
  def without_port
    original = Capybara.current_session.config.always_include_port
    Capybara.current_session.config.always_include_port = false
    yield
  ensure
    Capybara.current_session.config.always_include_port = original
  end

  # This method is equivalent to Capybara::RSpecMatchers#have_current_path
  # but checks the SPA route instead of the actual path.
  #
  # @see Capybara::RSpecMatchers#have_current_path
  #
  # @example
  #  expect(page).to have_current_route('login')
  # => checks for SPA route '/#login'
  #
  def have_current_route(route, app: self.class.metadata[:app], **options) # rubocop:disable Naming/PredicateName
    if route.is_a?(String)
      case app
      when :mobile
        if !route.start_with?('/')
          route = "/#{route}"
        end
        route = Regexp.new(Regexp.quote("/mobile#{route}"))
      else
        route = Regexp.new(Regexp.quote("/##{route}"))
      end
    end

    options.reverse_merge!(url: true)

    have_current_path(route, **options)
  end

  # This is a convenient wrapper method around #have_current_route
  # which requires no previous `expect(page).to ` call.
  #
  # @example
  #  expect_current_route('login')
  # => checks for SPA route '/#login'
  #
  def expect_current_route(route, app: self.class.metadata[:app], **options)
    expect(page).to have_current_route(route, app: app, **options)
  end

  # Create and migrate an object manager attribute and verify that it exists. Returns the newly attribute.
  #
  # Create a select attribute:
  # @example
  #  attribute = setup_attribute :object_manager_attribute_select
  #
  # Create a required text attribute:
  # @example
  #  attribute = setup_attribute :object_manager_attribute_text, :required_screen)
  #
  # Create a date attribute with custom parameters:
  # @example
  #  attribute = setup_attribute :object_manager_attribute_date,
  #                              data_option: {
  #                                'future' => true,
  #                                'past'   => false,
  #                                'diff'   => 24,
  #                                'null'   => true,
  #                              }
  #
  # return [attribute]
  def create_attribute(...)
    attribute = create(...)
    ObjectManager::Attribute.migration_execute
    page.driver.browser.navigate.refresh
    attribute
  end

  # opens the macro list in the ticket view via click
  #
  # @example
  #  open_macro_list
  #
  def open_macro_list
    click '.js-openDropdownMacro'
  end

  def open_article_meta
    retry_on_stale do
      wrapper = all('div.ticket-article-item').last

      wrapper.find('.article-content .textBubble').click
      wrapper.find('.article-content-meta .article-meta.top').in_fixed_position
    end
  end

  def use_template(template)
    field  = find('#form-template select[name="id"]')
    option = field.find(:option, template.name)
    option.select_option
    click '.sidebar-content .js-apply'
  end

  # Checks if modal is ready.
  # Returns modal DOM element or raises an error
  #
  # @param timeout [Integer] seconds to wait
  #
  # @return [Capybara::Element] modal DOM element
  def modal_ready(timeout: Capybara.default_max_wait_time)
    find('.modal.in.modal--ready', wait: timeout)
  rescue Capybara::ElementNotFound
    raise "Modal did not appear in #{timeout} seconds"
  end

  # Executes action inside of modal. Makes sure modal has opened and closes
  # Given block is executed within modal element
  # If RSpec's expect clause is present in the block, it does not wait for modal to close
  #
  # @param timeout [Integer] seconds to wait
  # @param disappears: [Boolean] wait for modal to close because of action taken in the block. Defaults to yes.
  # @yield [] A block to be executed scoped to the modal element
  def in_modal(timeout: Capybara.default_max_wait_time, disappears: nil, &block)
    elem = modal_ready(timeout: timeout)

    # check traces for RSpec's #expect
    trace = TracePoint.new(:call) do |tp|
      next if !(tp.method_id == :expect && tp.defined_class == RSpec::Matchers)

      # set disappers to false only if it was not set explicitly in method arguments
      disappears = false if disappears.nil?
    end

    trace.enable do
      within(elem, &block)
    end

    # return and don't wait for modal to disappear if disappears is not nil and falsey
    # if disappears is nill, default behavior is to wait
    return if !disappears.nil? && !disappears

    wait(timeout, message: "Modal did not disappear in #{timeout} seconds").until do
      elem.base.obscured?
    rescue *page.driver.invalid_element_errors
      true
    end
  end

  # Show the popover on hover
  #
  # @example
  # popover_on_hover(page.find('button.hover_me'))
  def popover_on_hover(element)
    move_mouse_to(element)
    move_mouse_by(5, 5)
  end

  # Scroll into view with javscript.
  #
  # @param position [Symbol] :top or :bottom, position of the scroll into view
  #
  # scroll_into_view('button.js-submit)
  #
  def scroll_into_view(css_selector, position: :top)
    page.execute_script("document.querySelector('#{css_selector}').scrollIntoView(#{position == :top})")
    sleep 0.3
  end

  # Close a tab in the taskbar.
  #
  # @param discard_changes [Boolean] if true, discard changes
  #
  # @example
  # taskbar_tab_close('Ticket-2')
  #
  def taskbar_tab_close(tab_data_key, discard_changes: true)
    retry_on_stale do
      taskbar_entry = find(:task_with, tab_data_key)

      move_mouse_to(taskbar_entry)
      move_mouse_by(5, 5)

      click ".tasks .task[data-key='#{tab_data_key}'] .js-close"

      return if !discard_changes

      in_modal do
        click '.js-submit'
      end
    end
  end

  private

  def wait_for_pending_login(skip_waiting)
    return if !ENV['FAKE_SELENIUM_LOGIN_PENDING']

    # When visiting the first route after login, confirm currently logged in user.
    ENV['FAKE_SELENIUM_LOGIN_PENDING'] = nil
    current_login if !skip_waiting

    nil
  end
end

RSpec.configure do |config|
  config.include CommonActions, type: :system
end
