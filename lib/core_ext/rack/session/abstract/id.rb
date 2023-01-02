# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rack/session/abstract/id'

module Rack
  module Session
    module Abstract
      class Persisted

        alias original_security_matches? security_matches?

        # https://github.com/rack/rack/blob/2.2.3/lib/rack/session/abstract/id.rb#L363-L366
        def security_matches?(request, options)
          options[:secure] = ::Session.secure_flag?
          original_security_matches?(request, options)
        end
      end
    end
  end
end
