# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'uri'

class GitHub
  class HttpClient
    attr_reader :api_token, :endpoint

    def initialize(endpoint, api_token)
      raise 'api_token required' if api_token.blank?
      raise 'endpoint required' if endpoint.blank? || endpoint.exclude?('/graphql') || endpoint.scan(URI::DEFAULT_PARSER.make_regexp).blank?

      @api_token = api_token
      @endpoint  = endpoint
    end

    def perform(payload)
      response = UserAgent.post(
        endpoint,
        payload,
        {
          headers:      headers,
          json:         true,
          open_timeout: 6,
          read_timeout: 16,
          log:          {
            facility: 'GitHub',
          },
          verify_ssl:   true,
        },
      )

      if !response.success?
        Rails.logger.error response.error
        raise __('GitHub request failed! Please have a look at the log file for details')
      end

      response.data
    end

    private

    def headers
      {
        Authorization: "bearer #{api_token}"
      }
    end
  end
end
