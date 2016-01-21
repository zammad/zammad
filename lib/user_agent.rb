# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

require 'net/http'
require 'net/https'
require 'net/ftp'
require 'tempfile'

class UserAgent

=begin

get http/https calls

  result = UserAgent.get('http://host/some_dir/some_file?param1=123')

  result = UserAgent.get(
    'http://host/some_dir/some_file?param1=123',
    {
      param1: 'some value',
    },
    {
      open_timeout: 4,
      read_timeout: 10,
    },
  )

returns

  result.body # as response

get json object

  result = UserAgent.get(
    'http://host/some_dir/some_file?param1=123',
    {},
    {
      json: true,
    }
  )

returns

  result.data # as json object

=end

  def self.get(url, params = {}, options = {}, count = 10)
    uri  = URI.parse(url)
    http = get_http(uri, options)

    # prepare request
    request = Net::HTTP::Get.new(uri, { 'User-Agent' => 'Zammad User Agent' })

    # http basic auth (if needed)
    request = set_basic_auth(request, options)

    # set params
    request = set_params(request, params, options)

    # start http call
    begin
      total_timeout = options[:total_timeout] || 60
      Timeout.timeout(total_timeout) do
        response = http.request(request)
        return process(response, uri, count, params, options)
      end
    rescue => e
      return Result.new(
        error: e.inspect,
        success: false,
        code: 0,
      )
    end
  end

=begin

post http/https calls

  result = UserAgent.post(
    'http://host/some_dir/some_file',
    {
      param1: 1,
      param2: 2,
    },
    {
      open_timeout: 4,
      read_timeout: 10,
      total_timeout: 60,
    },
  )

returns

  result # result object

=end

  def self.post(url, params = {}, options = {}, count = 10)
    uri  = URI.parse(url)
    http = get_http(uri, options)

    # prepare request
    request = Net::HTTP::Post.new(uri, { 'User-Agent' => 'Zammad User Agent' })

    # set params
    request = set_params(request, params, options)

    # http basic auth (if needed)
    request = set_basic_auth(request, options)

    # start http call
    begin
      total_timeout = options[:total_timeout] || 60
      Timeout.timeout(total_timeout) do
        response = http.request(request)
        return process(response, uri, count, params, options)
      end
    rescue => e
      return Result.new(
        error: e.inspect,
        success: false,
        code: 0,
      )
    end
  end

=begin

put http/https calls

  result = UserAgent.put(
    'http://host/some_dir/some_file',
    {
      param1: 1,
      param2: 2,
    },
    {
      open_timeout: 4,
      read_timeout: 10,
    },
  )

returns

  result # result object

=end

  def self.put(url, params = {}, options = {}, count = 10)
    uri  = URI.parse(url)
    http = get_http(uri, options)

    # prepare request
    request = Net::HTTP::Put.new(uri, { 'User-Agent' => 'Zammad User Agent' })

    # set params
    request = set_params(request, params, options)

    # http basic auth (if needed)
    request = set_basic_auth(request, options)

    # start http call
    begin
      total_timeout = options[:total_timeout] || 60
      Timeout.timeout(total_timeout) do
        response = http.request(request)
        return process(response, uri, count, params, options)
      end
    rescue => e
      return Result.new(
        error: e.inspect,
        success: false,
        code: 0,
      )
    end
  end

=begin

delete http/https calls

  result = UserAgent.delete(
    'http://host/some_dir/some_file',
    {
      open_timeout: 4,
      read_timeout: 10,
    },
  )

returns

  result # result object

=end

  def self.delete(url, options = {}, count = 10)
    uri  = URI.parse(url)
    http = get_http(uri, options)

    # prepare request
    request = Net::HTTP::Delete.new(uri, { 'User-Agent' => 'Zammad User Agent' })

    # http basic auth (if needed)
    request = set_basic_auth(request, options)

    # start http call
    begin
      total_timeout = options[:total_timeout] || 60
      Timeout.timeout(total_timeout) do
        response = http.request(request)
        return process(response, uri, count, {}, options)
      end
    rescue => e
      return Result.new(
        error: e.inspect,
        success: false,
        code: 0,
      )
    end
  end

=begin

perform get http/https/ftp calls

  result = UserAgent.request('ftp://host/some_dir/some_file.bin')

  result = UserAgent.request('http://host/some_dir/some_file.bin')

  result = UserAgent.request('https://host/some_dir/some_file.bin')

  # get request
  result = UserAgent.request(
    'http://host/some_dir/some_file?param1=123',
    {
      open_timeout: 4,
      read_timeout: 10,
    },
  )

returns

  result # result object

=end

  def self.request(url, options = {})

    uri = URI.parse(url)
    case uri.scheme.downcase
    when /ftp/
      ftp(uri, options)
    when /http|https/
      get(url, {}, options)
    end

  end

  def self.get_http(uri, options)
    http = Net::HTTP.new(uri.host, uri.port)

    http.open_timeout = options[:open_timeout] || 4
    http.read_timeout = options[:read_timeout] || 10

    if uri.scheme =~ /https/i
      http.use_ssl = true
      # @TODO verify_mode should be configurable
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    http
  end

  def self.set_basic_auth(request, options)

    # http basic auth (if needed)
    if options[:user] && options[:user] != '' && options[:password] && options[:password] != ''
      request.basic_auth options[:user], options[:password]
    end
    request
  end

  def self.set_params(request, params, options)
    if options[:json]
      request.add_field('Content-Type', 'application/json')
      if !params.empty?
        request.body = params.to_json
      end
    elsif !params.empty?
      request.set_form_data(params)
    end
    request
  end

  def self.process(response, uri, count, params, options)
    if !response
      return Result.new(
        error: "Can't connect to #{uri}, got no response!",
        success: false,
        code: 0,
      )
    end

    case response
    when Net::HTTPNotFound
      return Result.new(
        error: "No such file #{uri}, 404!",
        success: false,
        code: response.code,
      )
    when Net::HTTPClientError
      return Result.new(
        error: "Client Error: #{response.inspect}!",
        success: false,
        code: response.code,
      )
    when Net::HTTPInternalServerError
      return Result.new(
        error: "Server Error: #{response.inspect}!",
        success: false,
        code: response.code,
      )
    when Net::HTTPRedirection
      fail 'Too many redirections for the original URL, halting.' if count <= 0
      url = response['location']
      return get(url, params, options, count - 1)
    when Net::HTTPOK
      data = nil
      if options[:json] && !options[:jsonParseDisable] && response.body
        data = JSON.parse(response.body)
      end
      return Result.new(
        data: data,
        body: response.body,
        content_type: response['Content-Type'],
        success: true,
        code: response.code,
      )
    when Net::HTTPCreated
      data = nil
      if options[:json] && !options[:jsonParseDisable] && response.body
        data = JSON.parse(response.body)
      end
      return Result.new(
        data: data,
        body: response.body,
        content_type: response['Content-Type'],
        success: true,
        code: response.code,
      )
    end

    fail "Unable to process http call '#{response.inspect}'"
  end

  def self.ftp(uri, options)
    host       = uri.host
    filename   = File.basename(uri.path)
    remote_dir = File.dirname(uri.path)

    temp_file = Tempfile.new("download-#{filename}")
    temp_file.binmode

    begin
      Net::FTP.open(host) do |ftp|
        ftp.passive = true
        if options[:user] && options[:password]
          ftp.login(options[:user], options[:password])
        else
          ftp.login
        end
        ftp.chdir(remote_dir) unless remote_dir == '.'

        begin
          ftp.getbinaryfile(filename, temp_file)
        rescue => e
          return Result.new(
            error: e.inspect,
            success: false,
            code: '550',
          )
        end
      end
    rescue => e
      return Result.new(
        error: e.inspect,
        success: false,
        code: 0,
      )
    end

    contents = temp_file.read
    temp_file.close
    Result.new(
      body: contents,
      success: true,
      code: '200',
    )
  end

  class Result

    attr_reader :error
    attr_reader :body
    attr_reader :data
    attr_reader :code
    attr_reader :content_type

    def initialize(options)
      @success      = options[:success]
      @body         = options[:body]
      @data         = options[:data]
      @code         = options[:code]
      @content_type = options[:content_type]
      @error        = options[:error]
    end

    def success?
      return true if @success
      false
    end
  end
end
