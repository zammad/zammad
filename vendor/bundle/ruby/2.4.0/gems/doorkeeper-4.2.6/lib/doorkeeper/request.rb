require 'doorkeeper/request/authorization_code'
require 'doorkeeper/request/client_credentials'
require 'doorkeeper/request/code'
require 'doorkeeper/request/password'
require 'doorkeeper/request/refresh_token'
require 'doorkeeper/request/token'

module Doorkeeper
  module Request
    module_function

    def authorization_strategy(response_type)
      get_strategy response_type, authorization_response_types
    rescue NameError
      raise Errors::InvalidAuthorizationStrategy
    end

    def token_strategy(grant_type)
      get_strategy grant_type, token_grant_types
    rescue NameError
      raise Errors::InvalidTokenStrategy
    end

    def get_strategy(grant_or_request_type, available)
      fail Errors::MissingRequestStrategy unless grant_or_request_type.present?
      fail NameError unless available.include?(grant_or_request_type.to_s)
      "Doorkeeper::Request::#{grant_or_request_type.to_s.camelize}".constantize
    end

    def authorization_response_types
      Doorkeeper.configuration.authorization_response_types
    end
    private_class_method :authorization_response_types

    def token_grant_types
      Doorkeeper.configuration.token_grant_types
    end
    private_class_method :token_grant_types
  end
end
