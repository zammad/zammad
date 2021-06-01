# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationController::LogsHttpAccess
  extend ActiveSupport::Concern

  included do
    after_action :http_log
  end

  private

  def http_log_config(config)
    @http_log_support = config
  end

  # log http access
  def http_log
    return if !@http_log_support

    # request
    request_data = {
      content:          '',
      content_type:     request.headers['Content-Type'],
      content_encoding: request.headers['Content-Encoding'],
      source:           request.headers['User-Agent'] || request.headers['Server'],
    }
    request.headers.each do |key, value|
      next if key[0, 5] != 'HTTP_'

      request_data[:content] += if key == 'HTTP_COOKIE'
                                  "#{key}: xxxxx\n"
                                else
                                  "#{key}: #{value}\n"
                                end
    end
    body = request.body.read
    if body
      request_data[:content] += "\n#{body}"
    end
    request_data[:content] = request_data[:content].slice(0, 8000)

    # response
    response_data = {
      code:             response.status = response.code,
      content:          '',
      content_type:     nil,
      content_encoding: nil,
      source:           nil,
    }
    response.headers.each do |key, value|
      response_data[:content] += "#{key}: #{value}\n"
    end
    body = response.body
    if body
      response_data[:content] += "\n#{body}"
    end
    response_data[:content] = response_data[:content].slice(0, 8000)
    record = {
      direction: 'in',
      facility:  @http_log_support[:facility],
      url:       url_for(only_path: false, overwrite_params: {}),
      status:    response.status,
      ip:        request.remote_ip,
      request:   request_data,
      response:  response_data,
      method:    request.method,
    }
    HttpLog.create(record)
  end
end
