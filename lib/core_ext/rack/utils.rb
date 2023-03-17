# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rack/utils'

module Rack
  module Utils

    module_function

    singleton_class.alias_method :original_add_cookie_to_header, :add_cookie_to_header

    # https://github.com/rack/rack/blob/2.2.3/lib/rack/session/utils.rb#L223-L262
    def add_cookie_to_header(header, key, value)

      if value.is_a?(Hash)
        value[:secure] = ::Session.secure_flag?
      end

      original_add_cookie_to_header(header, key, value)
    end
  end
end
