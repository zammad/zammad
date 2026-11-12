# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module PlaywrightNative
  # For examples with authenticated_as: false, the others start logged in.
  module Authentication
    # The login form of the desktop view and of the mobile app.
    def sign_in(username:, password:, remember_me: false)
      fill_field('Username / Email', username)
      fill_field('Password', password)
      page.get_by_role('checkbox', name: 'Remember me').check if remember_me

      page.get_by_role('button', name: 'Sign in', exact: true).click
    end

    # Another user in a browser of their own, signed in through the login form. The helpers in
    #   the block act on that user's page, like with on_tab, and tabs opened there are that
    #   user's. The browser is closed afterwards.
    #
    # The fake login of the example's user signs in every session without a user, so it is off
    #   meanwhile. The example's page keeps its user, its session got one with its first request.
    def as_user(user, password: 'test')
      previous_page      = page
      previous_context   = browser_context
      example            = RSpec.current_example
      fake_login_user_id = ENV.delete('FAKE_LOGIN_USER_ID')
      context            = PlaywrightNative::Page.new_context(example)
      passed             = false

      PlaywrightNative::Page.collect_js_errors(context, @js_errors)
      @browser_context = context
      @page            = user_page = context.new_page

      example.metadata[:app] == :mobile ? open_mobile('/login') : open_desktop('/login')
      sign_in(username: user.login, password:)
      wait_for_test_flag('useSessionUserStore.getCurrentUser.loaded', skip_clearing: true)
      expect(page).to not_have_url(%r{/login$})

      yield.tap { passed = true }
    ensure
      # Restored first, so a browser that fails to close leaves the example with its own.
      @page            = previous_page
      @browser_context = previous_context
      ENV['FAKE_LOGIN_USER_ID'] = fake_login_user_id

      # A JavaScript error fails the example later on, its trace is wanted as well.
      failed = !passed || @js_errors.grep(PlaywrightNative::Page::JS_ERROR).any?
      PlaywrightNative::Page.close_context(context, example, user_page, failed:, name: user.login) if context
    end
  end
end

RSpec.configure do |config|
  config.include PlaywrightNative::Authentication, type: :playwright
end
