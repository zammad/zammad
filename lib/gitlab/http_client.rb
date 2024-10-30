# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'uri'

class GitLab
  class HttpClient
    attr_reader :api_token, :endpoint, :verify_ssl

    def initialize(endpoint, api_token, verify_ssl: true)
      raise __('Invalid GitLab configuration (missing endpoint or api_token).') if api_token.blank? || endpoint.blank? || endpoint.exclude?('/graphql') || endpoint.scan(URI::DEFAULT_PARSER.make_regexp).blank?

      @api_token = api_token
      @endpoint = endpoint
      @verify_ssl = verify_ssl
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
          verify_ssl:   verify_ssl,
        },
      )

      if !response.success?
        Rails.logger.error response.error
        raise __('GitLab request failed. Please have a look at the log file for details.')
      end

      response.data
    end

    def perform_rest_get_request(variables)
      uri = URI.parse(endpoint)
      return if uri.blank? || variables.blank?

      response = UserAgent.get(
        "#{uri.scheme}://#{uri.host}/api/v4/projects/#{ERB::Util.url_encode(variables[:fullpath])}/issues/#{variables[:issue_id]}",
        {},
        {
          headers:      headers,
          json:         true,
          open_timeout: 6,
          read_timeout: 16,
          log:          {
            facility: 'GitLab',
          },
          verify_ssl:   verify_ssl,
        },
      )

      if !response.success?
        Rails.logger.error response.error
        return
      end

      JSON.parse(response.body)
    end

    private

    def headers
      {
        'PRIVATE-TOKEN': @api_token
      }
    end
  end
end
