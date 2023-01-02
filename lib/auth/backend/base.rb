# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Auth
  class Backend
    class Base

      delegate :user, :password, to: :auth

      attr_reader :config, :auth

      # Base initialization for Auth backend object.
      #
      # @param config [Hash] backend configuration hash.
      # @param auth [Auth] the Auth object for the authentication.
      #
      # @example
      #  auth = Auth::Backend::Internal.new('admin@example.com', auth)
      def initialize(config, auth)
        @config = config
        @auth   = auth
      end

      def valid?
        return false if password.blank? && password_required?
        return false if !perform?

        authenticated?
      end

      private

      def password_required?
        true
      end

      def perform?
        raise NotImplementedError
      end

      def authenticated?
        raise NotImplementedError
      end
    end
  end
end
