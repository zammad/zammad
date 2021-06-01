# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module CommonActions

  delegate :app_host, to: Capybara

  # Performs a login with the given credentials and closes the clues (if present).
  # The 'remember me' can optionally be checked.
  #
  # @example
  #  login(
  #    username: 'master@example.com',
  #    password: 'test',
  #  )
  #
  # @example
  #  login(
  #    username:    'master@example.com',
  #    password:    'test',
  #    remember_me: true,
  #  )
  #
  # return [nil]
  def login(username:, password:, remember_me: false)
    visit '/'

    within('#login') do
      fill_in 'username', with: username
      fill_in 'password', with: password

      # check via label because checkbox is hidden
      click('.checkbox-replacement') if remember_me

      # submit
      click_button
    end

    wait(4).until_exists do
      current_login
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
  # => 'master@example.com'
  #
  # @return [String] the login of the currently logged in user.
  def current_login
    find('.user-menu .user a')[:title]
  end

  # Returns the User record for the currently logged in user.
  #
  # @example
  #  current_user.login
  # => 'master@example.com'
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
  def logout
    visit('logout')
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
  def visit(route)
    if route.include?('://')
      return without_port do
        super(route)
      end
    elsif !route.start_with?('/')
      route = "/##{route}"
    end
    super(route)
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
  def have_current_route(route, **options)
    if route.is_a?(String)
      route = Regexp.new(Regexp.quote("/##{route}"))
    end

    # wait 1 sec by default because Firefox is slow
    options.reverse_merge!(wait: 1, url: true)

    have_current_path(route, **options)
  end

  # This is a convenient wrapper method around #have_current_route
  # which requires no previous `expect(page).to ` call.
  #
  # @example
  #  expect_current_route('login')
  # => checks for SPA route '/#login'
  #
  def expect_current_route(route, **options)
    expect(page).to have_current_route(route, **options)
  end

  # Create and migrate an object manager attribute and verify that it exists. Returns the newly attribute.
  #
  # Create a select attribute:
  # @example
  #  attribute = setup_attribute :object_manager_attribute_select
  #
  # Create a required text attribute:
  # @example
  #  attribute = setup_attribute :object_manager_attribute_text,
  #                               screens: attributes_for(:required_screen)
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
  def create_attribute(attribute_name, attribute_parameters = {})
    attribute = create(attribute_name, attribute_parameters)
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
      wait(3).until do
        wrapper.find('.article-content-meta .article-meta.top').in_fixed_position
      end
    end
  end

  def use_template(template)
    wait(4).until do
      field  = find('#form-template select[name="id"]')
      option = field.find(:option, template.name)
      option.select_option
      click '.sidebar-content .js-apply'

      # this is a workaround for a race condition where
      # the template selection get's re-rendered after
      # a selection was made. The selection is lost and
      # the apply click has no effect.
      template.options.any? do |attribute, value|
        selector = %([name="#{attribute}"])
        next if !page.has_css?(selector, wait: 0)

        find(selector, wait: 0, visible: false).value == value
      end
    end
  end

  # Checks if modal is ready
  #
  # @param timeout [Integer] seconds to wait
  def modal_ready(timeout: 4)
    wait(timeout).until_exists { find('.modal.in', wait: 0) }
  end

  # Checks if modal has disappeared
  #
  # @param timeout [Integer] seconds to wait
  def modal_disappear(timeout: 4)
    wait(timeout).until_disappears { find('.modal', wait: 0) }
  end

  # Executes action inside of modal. Makes sure modal has opened and closes
  #
  # @param timeout [Integer] seconds to wait
  # @param wait_for_disappear [Bool] wait for modal to close
  def in_modal(timeout: 4, disappears: true, &block)
    modal_ready(timeout: timeout)

    within('.modal', &block)

    modal_disappear(timeout: timeout) if disappears
  end
end

RSpec.configure do |config|
  config.include CommonActions, type: :system
end
