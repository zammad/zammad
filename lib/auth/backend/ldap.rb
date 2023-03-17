# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Auth
  class Backend
    class Ldap < Auth::Backend::Base

      private

      def source
        LdapSource.by_user(user)
      end

      def login_valid?(ldap_user)
        # get from config or fallback to login
        # for a list of user attributes which should
        # be used for logging in
        login_attributes = config[:login_attributes] || %w[login]

        login_attributes.any? do |attribute|
          ldap_user.valid?(user[attribute], password)
        end
      end

      # Validation against the configured ldap integration.
      #
      # @returns [Boolean] true if the validation works, otherwise false.
      def authenticated?
        return if !source

        ldap_user = ::Ldap::User.new(source.preferences)

        authed = login_valid?(ldap_user)
        log_auth_result(authed)
        authed
      rescue => e
        message = "Can't connect to ldap backend #{e}"
        Rails.logger.info message
        Rails.logger.info e
        log(
          status:   'failed',
          response: message,
        )
        false
      end

      # Checks the default behaviour and as a addition if the ldap integration is currently active.
      #
      # @returns [Boolean] true if the ldap integration is active and the default behaviour matches.
      def perform?
        user.source =~ %r{^Ldap::(\d+)$} && Setting.get('ldap_integration')
      end

      # Logs the auth result
      #
      # @param authed [Boolean] true if the user is authed, otherwise false.
      def log_auth_result(authed)
        result = authed ? 'success' : 'failed'
        log(
          status: result,
        )
      end

      # Created the http log for the current authentication.
      #
      # @param status [String] the status of the ldap authentication.
      # @param response [String] the response message.
      def log(status:, response: nil)
        HttpLog.create(
          direction:     'out',
          facility:      'ldap',
          url:           "bind -> #{user.login}",
          status:        status,
          ip:            nil,
          request:       { content: user.login },
          response:      { content: response || status },
          method:        'tcp',
          created_by_id: 1,
          updated_by_id: 1,
        )
      end
    end
  end
end
