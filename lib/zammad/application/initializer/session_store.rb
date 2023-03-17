# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")

module Zammad
  class Application
    module Initializer
      module SessionStore
        STORE_TYPE  = :active_record_store # default: :cookie_store
        SESSION_KEY = "_zammad_session_#{Digest::MD5.hexdigest(Rails.root.to_s)[5..15]}".freeze # default: '_zammad_session'

        def self.perform
          # it's important to register the session store at initialization time
          # otherwise the store won't be used
          # ATTENTION: Rails/Rack Cookie handling was customized to call `Session.secure_flag?`
          # instead of accessing the `:secure` key (default Rack/Rails behavior).
          # See: lib/core_ext/action_dispatch/middleware/cookies.rb
          # See: lib/core_ext/rack/session/abstract/id.rb
          # See: lib/core_ext/rack/session/utils.rb
          Rails.application.config.session_store STORE_TYPE,
                                                 key: SESSION_KEY

          # once the application is initialized and we can access the models
          # we need to update the session_class
          Rails.application.reloader.to_prepare do
            ActionDispatch::Session::ActiveRecordStore.session_class = Session
          end
        end
      end
    end
  end
end
