# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
        return false if !perform?

        authenticated?
      end

      private

      def perform?
        raise NotImplementedError
      end

      def authenticated?
        raise NotImplementedError
      end
    end
  end
end
