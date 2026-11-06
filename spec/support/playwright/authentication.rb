# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module PlaywrightNative
  # For examples with authenticated_as: false, the others start logged in.
  module Authentication
    # The login form of the desktop view and of the mobile app.
    def sign_in(username:, password:, remember_me: false)
      fill_field('Username / Email', username)
      fill_field('Password', password)
      # The checkbox itself is hidden behind its styled label.
      page.get_by_text('Remember me', exact: true).click if remember_me

      page.get_by_role('button', name: 'Sign in', exact: true).click
    end
  end
end

RSpec.configure do |config|
  config.include PlaywrightNative::Authentication, type: :playwright
end
