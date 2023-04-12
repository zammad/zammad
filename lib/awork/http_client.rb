require 'uri'

class Awork
  class HttpClient
    attr_reader :api_token, :endpoint

    def initialize(endpoint, api_token)
      raise 'api_token required' if api_token.blank?
      raise 'endpoint required' if endpoint.blank? || endpoint.scan(URI::DEFAULT_PARSER.make_regexp).blank?

      @api_token = api_token
      @endpoint = endpoint
    end

    def perform(method='post', path='', payload={})
      method = method.downcase
      response = UserAgent.send(method.to_sym, endpoint+path, payload,
        {
          headers:      headers,
          json:         true,
          open_timeout: 6,
          read_timeout: 16,
          log:          {
            facility: 'Awork',
          },
          verify_ssl:   true,
        }
      )

      if !response.success?
        Rails.logger.error response.error
        raise __('Awork request failed! Please have a look at the log file for details')
      end

      response.data
    end

    private

    def headers
      {
        'Authorization': "Bearer #{@api_token}"
      }
    end
  end
end