# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'uri'

class GitLab
  class HttpClient
    attr_reader :api_token, :endpoint

    def initialize(endpoint, api_token)
      raise 'api_token required' if api_token.blank?
      raise 'endpoint required' if endpoint.blank? || endpoint.exclude?('/graphql') || endpoint.scan(URI::DEFAULT_PARSER.make_regexp).blank?

      @api_token = api_token
      @endpoint = endpoint
    end

    # returns path of the subfolder of the endpoint if exists
    def endpoint_path
      path = URI.parse(endpoint).path
      return if path.blank?
      return if path == '/api/graphql'

      if path.start_with?('/')
        path = path[1..]
      end

      path.sub('api/graphql', '')
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
            facility: 'GitLab',
          },
          verify_ssl:   true,
        },
      )

      if !response.success?
        Rails.logger.error response.error
        raise __('GitLab request failed! Please have a look at the log file for details')
      end

      response.data
    end

    private

    def headers
      {
        'PRIVATE-TOKEN': @api_token
      }
    end
  end
end
