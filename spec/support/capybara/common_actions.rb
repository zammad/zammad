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

    return if User.find_by(login: current_login).preferences[:intro]

    find(:clues_close, wait: 3).in_fixed_postion.click
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

  # Overwrites the Capybara::Session#visit method to allow SPA navigation.
  # All routes not starting with `/` will be handled as SPA routes.
  #
  # @see Capybara::Session#visit
  #
  # @example
  #  visit('logout')
  # => visited SPA route '/#logout'
  #
  # @example
  #  visit('/test/ui')
  # => visited regular route '/test/ui'
  #
  def visit(route)
    if !route.start_with?('/')
      route = "/##{route}"
    end
    super(route)
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

end

RSpec.configure do |config|
  config.include CommonActions, type: :system
end
