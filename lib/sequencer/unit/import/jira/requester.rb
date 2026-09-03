# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shared HTTP helper for the Jira Cloud REST API (v3).
#
# Authentication uses HTTP basic auth with the account email address and an
# API token, as required by Jira Cloud. The module is meant to be `include`d
# into a unit so its methods become available as instance methods.
module Sequencer::Unit::Import::Jira::Requester
  API_PREFIX = 'rest/api/3'.freeze

  # Performs a request with a small retry loop for rate limiting (429) and
  # transient errors. Returns the parsed JSON body (Hash/Array) or nil.
  def request_json(method:, api_path:, params: nil, body: nil)
    10.times do |iteration|
      response = perform_request(
        method:   method,
        api_path: api_path,
        params:   params,
        body:     body,
      )

      return parse_json(response) if response.is_a?(Net::HTTPOK)
      return nil if response.is_a?(Net::HTTPNotFound)

      handle_error(response, iteration)
    rescue => e
      handle_exception(e, iteration)
    end

    nil
  end

  def get_json(api_path, params: nil)
    request_json(method: :get, api_path: api_path, params: params)
  end

  def post_json(api_path, body)
    request_json(method: :post, api_path: api_path, body: body)
  end

  def perform_request(method:, api_path:, params: nil, body: nil)
    uri = URI("#{endpoint}/#{API_PREFIX}/#{api_path}")
    uri.query = URI.encode_www_form(params) if params.present?

    headers = { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', read_timeout: 600) do |http|
      request = build_request(method, uri, headers, body)
      request.basic_auth(Setting.get('import_jira_email'), Setting.get('import_jira_api_token'))
      return http.request(request)
    end
  end

  private

  def build_request(method, uri, headers, body)
    klass = method.to_sym == :post ? Net::HTTP::Post : Net::HTTP::Get
    request = klass.new(uri, headers)
    request.body = body.to_json if body.present?
    request
  end

  def endpoint
    Setting.get('import_jira_endpoint').to_s.chomp('/')
  end

  def parse_json(response)
    JSON.parse(response.body)
  rescue JSON::ParserError => e
    logger.error e
    nil
  end

  def handle_error(response, iteration)
    sleep_for = 10
    case response
    when Net::HTTPTooManyRequests
      sleep_for = response.header['retry-after'].to_i + 10
      logger.info "Rate limit (429 Too Many Requests). Sleeping #{sleep_for} seconds and retry (##{iteration + 1}/10)."
    else
      logger.info "Unknown response: #{response.inspect}. Sleeping 10 seconds and retry (##{iteration + 1}/10)."
    end

    sleep sleep_for
  end

  def handle_exception(e, iteration)
    logger.error e
    logger.info "Sleeping 10 seconds after #{e.class.name} and retry (##{iteration + 1}/10)."

    sleep 10
  end
end
