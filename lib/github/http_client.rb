# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
require 'graphql/client'
require 'graphql/client/http'

class GitHub
  class HttpClient < ::GraphQL::Client::HTTP

    def initialize(endpoint, api_token)
      raise 'api_token required' if api_token.blank?
      raise 'endpoint required' if endpoint.blank?

      @api_token = api_token

      super(endpoint)
    end

    def headers(_context)
      {
        Authorization: "bearer #{@api_token}"
      }
    end
  end
end
