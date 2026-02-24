# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rack/utils'

module Rack
  module Utils

    module_function

    if Rack::Utils.respond_to?(:add_cookie_to_header)
      # Rack 2.x
      singleton_class.alias_method :original_add_cookie_to_header, :add_cookie_to_header

      # https://github.com/rack/rack/blob/2.2.3/lib/rack/session/utils.rb#L223-L262
      def add_cookie_to_header(header, key, value)
        value[:secure] = ::Session.secure_flag? if value.is_a?(Hash)
        original_add_cookie_to_header(header, key, value)
      end
    else
      # Rack 3.1+ — add_cookie_to_header was removed; set_cookie_header! is now used
      singleton_class.alias_method :original_set_cookie_header!, :set_cookie_header!

      def set_cookie_header!(headers, key, value)
        value[:secure] = ::Session.secure_flag? if value.is_a?(Hash)
        original_set_cookie_header!(headers, key, value)
      end
    end
  end
end
