require 'doorkeeper/request/strategy'

module Doorkeeper
  module Request
    class Password < Strategy
      delegate :credentials, :resource_owner, :parameters, :client, to: :server

      def request
        @request ||= OAuth::PasswordAccessTokenRequest.new(
          Doorkeeper.configuration,
          client,
          resource_owner,
          parameters
        )
      end
    end
  end
end
