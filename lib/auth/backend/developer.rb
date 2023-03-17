# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Auth
  class Backend
    class Developer < Auth::Backend::Base

      private

      # Special development/test password validation.
      # * For the developer mode the password 'test' is allowed for every User.
      # * For the test environment the password can be blank if also the user password is currently blank.
      #
      # @returns [Boolean] true if the validation works, otherwise false.
      def authenticated?
        if valid_for_developer_mode? || valid_for_test_environment?
          Rails.logger.info "System in test/developer mode, authentication for user #{user.login} ok."
          return true
        end

        false
      end

      # No password required for developer mode and test environment.
      #
      # @returns [Boolean] false
      def password_required?
        false
      end

      # Overwrites the default behaviour to check for a allowed environment.
      #
      # @returns [Boolean] true if the environment is development or test.
      def perform?
        allowed_environment?
      end

      # Check for allowed environments.
      #
      # @returns [Boolean] true if one allowed environment is active.
      def allowed_environment?
        Setting.get('developer_mode') == true || Rails.env.test?
      end

      # Validate password for test environment.
      #
      # @returns [Boolean] true if password and user password is blank, otherwise false.
      def valid_for_test_environment?
        Rails.env.test? && password.blank? && user.password.blank?
      end

      # Validate password for test environment.
      #
      # @returns [Boolean] true if the given password is 'test', otherwise false.
      def valid_for_developer_mode?
        Setting.get('developer_mode') == true && password == 'test'
      end
    end
  end
end
