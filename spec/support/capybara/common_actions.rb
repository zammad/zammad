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
end

RSpec.configure do |config|
  config.include CommonActions, type: :system
end
