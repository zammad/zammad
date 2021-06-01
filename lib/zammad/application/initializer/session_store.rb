# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")

module Zammad
  class Application
    class Initializer
      module SessionStore
        STORE_TYPE  = :active_record_store # default: :cookie_store
        SESSION_KEY = "_zammad_session_#{Digest::MD5.hexdigest(Rails.root.to_s)[5..15]}".freeze # default: '_zammad_session'

        def self.perform
          ActionDispatch::Session::ActiveRecordStore.session_class = Session
          Rails.application.config.session_store STORE_TYPE,
                                                 key:    SESSION_KEY,
                                                 secure: secure?
        end

        def self.secure?
          Setting.get('http_type') == 'https'
        rescue ActiveRecord::StatementInvalid
          false
        end
        private_class_method :secure?
      end
    end
  end
end
