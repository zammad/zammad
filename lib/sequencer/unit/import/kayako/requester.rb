# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Sequencer::Unit::Import::Kayako::Requester
  mattr_accessor :session_id

  def request(api_path:, params: nil)
    10.times do |iteration|
      response = perform_request(
        api_path: api_path,
        params:   params,
      )

      if response.is_a? Net::HTTPOK
        refresh_session_id(response)
        return response
      end

      handle_error response, iteration
    rescue Net::HTTPClientError => e
      handle_exception e, iteration
    end

    nil
  end

  def handle_error(response, iteration)
    reset_session_id if response.is_a? Net::HTTPUnauthorized

    sleep_for = 10
    case response
    when Net::HTTPTooManyRequests
      sleep_for = response.header['retry-after'].to_i + 10
      logger.info "Rate limit: #{response.header.to_hash} (429 Too Many Requests). Sleeping #{sleep_for} seconds and retry (##{iteration + 1}/10)."
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

  def refresh_session_id(response)
    return if response.header['content-type'] != 'application/json'

    body = JSON.parse(response.body)

    return if body['session_id'].blank?

    self.session_id = body['session_id']
  end

  def reset_session_id
    self.session_id = nil
  end

  def perform_request(api_path:, params: nil)
    uri = URI("#{Setting.get('import_kayako_endpoint')}/#{api_path}")
    uri.query = URI.encode_www_form(params) if params.present?
    headers = {
      'Content-Type' => 'application/json',
      'X-Session-ID' => session_id
    }

    Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 600) do |http|
      # for those special moments...
      # http.set_debug_output($stdout)
      request = Net::HTTP::Get.new(uri, headers)
      if session_id.blank?
        request.basic_auth(Setting.get('import_kayako_endpoint_username'), Setting.get('import_kayako_endpoint_password'))
      end
      return http.request(request)
    end
  end
end
