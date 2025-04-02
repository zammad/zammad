# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'net/http'
require 'net/https'

class UserAgent

  # Make HTTP request via GET method
  #
  # @see .make_connection
  def self.get(...)
    make_connection(:get, ...)
  end

  # Make HTTP request via POST method
  #
  # @see .make_connection
  def self.post(...)
    make_connection(:post, ...)
  end

  # Make HTTP request via PATCH method
  #
  # @see .make_connection
  def self.patch(...)
    make_connection(:patch, ...)
  end

  # Make HTTP request via PUT method
  #
  # @see .make_connection
  def self.put(...)
    make_connection(:put, ...)
  end

  # Make HTTP request via DELETE method
  #
  # @see .make_connection
  def self.delete(...)
    make_connection(:delete, ...)
  end

  def self.get_http(uri, options)

    proxy = options['proxy'] || Setting.get('proxy')
    proxy_no = options['proxy_no'] || Setting.get('proxy_no') || ''
    proxy_no = proxy_no.split(',').map(&:strip) || []
    proxy_no.push('localhost', '127.0.0.1', '::1')
    if proxy.present? && proxy_no.exclude?(uri.host.downcase)
      if proxy =~ %r{^(.+?):(.+?)$}
        proxy_host = $1
        proxy_port = $2
      end

      if proxy_host.blank? || proxy_port.blank?
        raise "Invalid proxy address: #{proxy} - expect e.g. proxy.example.com:3128"
      end

      proxy_username = options['proxy_username'] || Setting.get('proxy_username')
      if proxy_username.blank?
        proxy_username = nil
      end
      proxy_password = options['proxy_password'] || Setting.get('proxy_password')
      if proxy_password.blank?
        proxy_password = nil
      end

      http = Net::HTTP::Proxy(proxy_host, proxy_port, proxy_username, proxy_password).new(uri.host, uri.port)
    else
      http = Net::HTTP.new(uri.host, uri.port)
    end

    http.open_timeout = options[:open_timeout] || 4
    http.read_timeout = options[:read_timeout] || 10

    if uri.scheme == 'https'
      http.use_ssl = true

      if options.fetch(:verify_ssl, true)
        Certificate::ApplySSLCertificates.ensure_fresh_ssl_context
      else
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end

    # http.set_debug_output($stdout) if options[:debug]

    http
  end

  def self.set_basic_auth(request, options)

    # http basic auth (if needed)
    if options[:user].present? && options[:password].present?
      request.basic_auth options[:user], options[:password]
    end
    request
  end

  def self.set_bearer_token_auth(request, options)
    request.tap do |req|
      next if options[:bearer_token].blank?

      req['Authorization'] = "Bearer #{options[:bearer_token]}"
    end
  end

  def self.parse_uri(url, params = {}, method = nil)
    uri = URI.parse(url)

    if method == :get && params.present?
      uri.query = [uri.query, URI.encode_www_form(params)].join('&')
    end

    uri
  end

  def self.set_params(request, params, options)
    if options[:json]
      if !request.is_a?(Net::HTTP::Get) # GET requests pass params in query, see 'parse_uri'.
        request.add_field('Content-Type', 'application/json; charset=utf-8')
        if params.present?
          request.body = params.to_json
        end
      end
    elsif params.present?
      request.set_form_data(params)
    end
    request
  end

  def self.set_headers(request, options)
    defaults = { 'User-Agent' => __('Zammad User Agent') }
    headers  = defaults.merge(options.fetch(:headers, {}))

    headers.each do |header, value|
      request[header] = value
    end

    request
  end

  def self.set_signature(request, options)
    return request if options[:signature_token].blank?
    return request if request.body.blank?

    signature = OpenSSL::HMAC.hexdigest('sha1', options[:signature_token], request.body)
    request['X-Hub-Signature'] = "sha1=#{signature}"

    request
  end

  def self.log(url, request, response, options)
    return if !options[:log]

    # request
    request_data = {
      content:          '',
      content_type:     request['Content-Type'],
      content_encoding: request['Content-Encoding'],
      source:           request['User-Agent'] || request['Server'],
    }
    request.each_header do |key, value|
      request_data[:content] += "#{key}: #{value}\n"
    end
    body = request.body
    if body
      request_data[:content] += "\n#{body}"
    end

    # response
    response_data = {
      code:             0,
      content:          '',
      content_type:     nil,
      content_encoding: nil,
      source:           nil,
    }
    if response
      response_data[:code] = response.code
      response_data[:content_type] = response['Content-Type']
      response_data[:content_encoding] = response['Content-Encoding']
      response_data[:source] = response['User-Agent'] || response['Server']
      response.each_header do |key, value|
        response_data[:content] += "#{key}: #{value}\n"
      end
      body = response.body
      if body
        response_data[:content] += "\n#{body}"
      end
    end

    record = {
      direction: 'out',
      facility:  options[:log][:facility],
      url:       url,
      status:    response_data[:code],
      ip:        nil,
      request:   request_data,
      response:  response_data,
      method:    request.method,
    }
    HttpLog.create(record)
  end

  def self.process(request, response, uri, count, params, options) # rubocop:disable Metrics/ParameterLists
    log(uri.to_s, request, response, options)

    if !response
      return Result.new(
        error:   "Can't connect to #{uri}, got no response!",
        success: false,
        code:    0,
      )
    end

    case response
    when Net::HTTPNotFound
      return Result.new(
        error:   "No such file #{uri}, 404!",
        success: false,
        code:    response.code,
        body:    response.body,
        header:  response.each_header.to_h,
      )
    when Net::HTTPClientError
      return Result.new(
        error:   "Client Error: #{response.inspect}!",
        success: false,
        code:    response.code,
        body:    response.body,
        header:  response.each_header.to_h,
      )
    when Net::HTTPInternalServerError
      return Result.new(
        error:   "Server Error: #{response.inspect}!",
        success: false,
        code:    response.code,
        body:    response.body,
        header:  response.each_header.to_h,
      )
    when Net::HTTPRedirection
      if options[:do_not_follow_redirects]
        raise __('The server returned a redirect response, but the current operation does not allow redirects.')
      end

      if count <= 0
        raise __('Too many redirections for the original URL, halting.')
      end

      url = response['location']
      return get(url, params, options, count - 1)
    when Net::HTTPSuccess
      data = nil
      if options[:json] && !options[:jsonParseDisable] && response.body
        data = JSON.parse(response.body)
      end
      return Result.new(
        data:         data,
        body:         response.body,
        content_type: response['Content-Type'],
        success:      true,
        code:         response.code,
        header:       response.each_header.to_h,
      )
    end

    raise "Unable to process http call '#{response.inspect}'"
  end

  def self.handled_open_timeout(tries)
    tries ||= 1

    tries.times do |index|
      yield
    rescue Net::OpenTimeout
      raise if (index + 1) == tries
    end
  end

  # Base method for making connection
  #
  # @param method [Symbol] HTTP request method style to use. Must be Net::HTTP::Class
  # @param url [String] full URL to request
  # @param params [Hash] to add either to GET URL or submit as POST-style data
  # @param options [Hash]
  # @option options [String] :send_as_raw_body to submit as raw POST-style request data body
  # @option options [Integer] :total_timeout of connection
  # @option options [Integer] :open_socket_tries count to retry connection
  # @option options [Boolean] :verify_ssl
  # @option options [Hash] :headers to apply to request
  # @option options [String] :signature_token to set as X-Hub-Sighature header
  # @option options [Boolean] :json is POST-style data parameters posted as JSON and response shall be parsed as JSON
  # @option options [Boolean] :jsonParseDisable disable response parsing as JSON of :json is enabled
  # @option options [String] :user for basic authentication
  # @option options [String] :password for basic authentication
  # @option options [String] :bearer_token for token authentication
  # @option options [Hash] :log enable logging
  # @option options [String] :proxy address
  # @option options [String] :proxy_no list of address to skip proxy for
  # @option options [String] :proxy_username
  # @option options [String] :proxy_password
  # @option options [Integer] :open_timeout
  # @option options [Integer] :read_timeout
  # @option options [Boolean] :do_not_follow_redirects
  # @option log [String] :facility is sub-key as in options[:log][:facility] providing name to use when logging in HttpLog
  # @param count [Integer] of redirects. Counts towards zero and then aborts
  #
  # @example
  #
  # result = UserAgent.make_connection(:get, 'http://host/some_dir/some_file?param1=123',
  #   { param1: 'some value' } , { option: value })
  # result.data => { parsed: 'json' }
  #
  # @return [Result]
  def self.make_connection(method, url, params = {}, options = {}, count = 10)
    uri  = parse_uri(url, params, method)
    http = get_http(uri, options)

    # prepare request
    request = Net::HTTP.const_get(method.capitalize).new(uri)

    # set headers
    request = set_headers(request, options)

    # set params for non-get requests
    if method != :get
      request = set_params(request, params, options)
    end

    # http basic auth (if needed)
    request = set_basic_auth(request, options)

    # bearer token auth (if needed)
    request = set_bearer_token_auth(request, options)

    # add signature
    request = set_signature(request, options)

    # start http call
    begin
      total_timeout = options[:total_timeout] || 60

      handled_open_timeout(options[:open_socket_tries]) do
        Timeout.timeout(total_timeout) do
          response = if (send_as_raw_body = options[:send_as_raw_body])
                       http.request(request, send_as_raw_body)
                     else
                       http.request(request)
                     end
          return process(request, response, uri, count, params, options)
        end
      end
    rescue => e
      log(url, request, nil, options)
      Result.new(
        error:   e.inspect,
        success: false,
        code:    0,
      )
    end
  end

  class Result

    attr_reader :error, :body, :data, :code, :content_type, :header

    def initialize(options)
      @success      = options[:success]
      @body         = options[:body]
      @data         = options[:data]
      @code         = options[:code]
      @content_type = options[:content_type]
      @error        = options[:error]
      @header       = options[:header]
    end

    def success?
      return true if @success

      false
    end
  end
end
