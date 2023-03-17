# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'action_dispatch/middleware/cookies'

module ActionDispatch
  class Cookies
    class CookieJar

      alias original_write_cookie? write_cookie?

      # https://github.com/rails/rails/blob/v6.0.4/actionpack/lib/action_dispatch/middleware/cookies.rb#L447-L449
      def write_cookie?(cookie)
        original_write_cookie?(cookie.merge(secure: ::Session.secure_flag?))
      end
    end
  end
end
