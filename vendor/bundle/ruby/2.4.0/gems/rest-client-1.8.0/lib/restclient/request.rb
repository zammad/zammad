require 'tempfile'
require 'mime/types'
require 'cgi'
require 'netrc'
require 'set'

module RestClient
  # This class is used internally by RestClient to send the request, but you can also
  # call it directly if you'd like to use a method not supported by the
  # main API.  For example:
  #
  #   RestClient::Request.execute(:method => :head, :url => 'http://example.com')
  #
  # Mandatory parameters:
  # * :method
  # * :url
  # Optional parameters (have a look at ssl and/or uri for some explanations):
  # * :headers a hash containing the request headers
  # * :cookies will replace possible cookies in the :headers
  # * :user and :password for basic auth, will be replaced by a user/password available in the :url
  # * :block_response call the provided block with the HTTPResponse as parameter
  # * :raw_response return a low-level RawResponse instead of a Response
  # * :max_redirects maximum number of redirections (default to 10)
  # * :verify_ssl enable ssl verification, possible values are constants from
  #     OpenSSL::SSL::VERIFY_*, defaults to OpenSSL::SSL::VERIFY_PEER
  # * :timeout and :open_timeout are how long to wait for a response and to
  #     open a connection, in seconds. Pass nil to disable the timeout.
  # * :ssl_client_cert, :ssl_client_key, :ssl_ca_file, :ssl_ca_path,
  #     :ssl_cert_store, :ssl_verify_callback, :ssl_verify_callback_warnings
  # * :ssl_version specifies the SSL version for the underlying Net::HTTP connection
  # * :ssl_ciphers sets SSL ciphers for the connection. See
  #     OpenSSL::SSL::SSLContext#ciphers=
  class Request

    attr_reader :method, :url, :headers, :cookies,
                :payload, :user, :password, :timeout, :max_redirects,
                :open_timeout, :raw_response, :processed_headers, :args,
                :ssl_opts

    def self.execute(args, & block)
      new(args).execute(& block)
    end

    # This is similar to the list now in ruby core, but adds HIGH and RC4-MD5
    # for better compatibility (similar to Firefox) and moves AES-GCM cipher
    # suites above DHE/ECDHE CBC suites (similar to Chromium).
    # https://github.com/ruby/ruby/commit/699b209cf8cf11809620e12985ad33ae33b119ee
    #
    # This list will be used by default if the Ruby global OpenSSL default
    # ciphers appear to be a weak list.
    DefaultCiphers = %w{
      !aNULL
      !eNULL
      !EXPORT
      !SSLV2
      !LOW

      ECDHE-ECDSA-AES128-GCM-SHA256
      ECDHE-RSA-AES128-GCM-SHA256
      ECDHE-ECDSA-AES256-GCM-SHA384
      ECDHE-RSA-AES256-GCM-SHA384
      DHE-RSA-AES128-GCM-SHA256
      DHE-DSS-AES128-GCM-SHA256
      DHE-RSA-AES256-GCM-SHA384
      DHE-DSS-AES256-GCM-SHA384
      AES128-GCM-SHA256
      AES256-GCM-SHA384
      ECDHE-ECDSA-AES128-SHA256
      ECDHE-RSA-AES128-SHA256
      ECDHE-ECDSA-AES128-SHA
      ECDHE-RSA-AES128-SHA
      ECDHE-ECDSA-AES256-SHA384
      ECDHE-RSA-AES256-SHA384
      ECDHE-ECDSA-AES256-SHA
      ECDHE-RSA-AES256-SHA
      DHE-RSA-AES128-SHA256
      DHE-RSA-AES256-SHA256
      DHE-RSA-AES128-SHA
      DHE-RSA-AES256-SHA
      DHE-DSS-AES128-SHA256
      DHE-DSS-AES256-SHA256
      DHE-DSS-AES128-SHA
      DHE-DSS-AES256-SHA
      AES128-SHA256
      AES256-SHA256
      AES128-SHA
      AES256-SHA
      ECDHE-ECDSA-RC4-SHA
      ECDHE-RSA-RC4-SHA
      RC4-SHA

      HIGH
      +RC4
      RC4-MD5
    }.join(":")

    # A set of weak default ciphers that we will override by default.
    WeakDefaultCiphers = Set.new([
      "ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW",
    ])

    SSLOptionList = %w{client_cert client_key ca_file ca_path cert_store
                       version ciphers verify_callback verify_callback_warnings}

    def initialize args
      @method = args[:method] or raise ArgumentError, "must pass :method"
      @headers = args[:headers] || {}
      if args[:url]
        @url = process_url_params(args[:url], headers)
      else
        raise ArgumentError, "must pass :url"
      end
      @cookies = @headers.delete(:cookies) || args[:cookies] || {}
      @payload = Payload.generate(args[:payload])
      @user = args[:user]
      @password = args[:password]
      if args.include?(:timeout)
        @timeout = args[:timeout]
      end
      if args.include?(:open_timeout)
        @open_timeout = args[:open_timeout]
      end
      @block_response = args[:block_response]
      @raw_response = args[:raw_response] || false

      @ssl_opts = {}

      if args.include?(:verify_ssl)
        v_ssl = args.fetch(:verify_ssl)
        if v_ssl
          if v_ssl == true
            # interpret :verify_ssl => true as VERIFY_PEER
            @ssl_opts[:verify_ssl] = OpenSSL::SSL::VERIFY_PEER
          else
            # otherwise pass through any truthy values
            @ssl_opts[:verify_ssl] = v_ssl
          end
        else
          # interpret all falsy :verify_ssl values as VERIFY_NONE
          @ssl_opts[:verify_ssl] = OpenSSL::SSL::VERIFY_NONE
        end
      else
        # if :verify_ssl was not passed, default to VERIFY_PEER
        @ssl_opts[:verify_ssl] = OpenSSL::SSL::VERIFY_PEER
      end

      SSLOptionList.each do |key|
        source_key = ('ssl_' + key).to_sym
        if args.has_key?(source_key)
          @ssl_opts[key.to_sym] = args.fetch(source_key)
        end
      end

      # If there's no CA file, CA path, or cert store provided, use default
      if !ssl_ca_file && !ssl_ca_path && !@ssl_opts.include?(:cert_store)
        @ssl_opts[:cert_store] = self.class.default_ssl_cert_store
      end

      unless @ssl_opts.include?(:ciphers)
        # If we're on a Ruby version that has insecure default ciphers,
        # override it with our default list.
        if WeakDefaultCiphers.include?(
             OpenSSL::SSL::SSLContext::DEFAULT_PARAMS.fetch(:ciphers))
          @ssl_opts[:ciphers] = DefaultCiphers
        end
      end

      @tf = nil # If you are a raw request, this is your tempfile
      @max_redirects = args[:max_redirects] || 10
      @processed_headers = make_headers headers
      @args = args
    end

    def execute & block
      uri = parse_url_with_auth(url)
      transmit uri, net_http_request_class(method).new(uri.request_uri, processed_headers), payload, & block
    ensure
      payload.close if payload
    end

    # SSL-related options
    def verify_ssl
      @ssl_opts.fetch(:verify_ssl)
    end
    SSLOptionList.each do |key|
      define_method('ssl_' + key) do
        @ssl_opts[key.to_sym]
      end
    end

    # Extract the query parameters and append them to the url
    def process_url_params url, headers
      url_params = {}
      headers.delete_if do |key, value|
        if 'params' == key.to_s.downcase && value.is_a?(Hash)
          url_params.merge! value
          true
        else
          false
        end
      end
      unless url_params.empty?
        query_string = url_params.collect { |k, v| "#{k.to_s}=#{CGI::escape(v.to_s)}" }.join('&')
        url + "?#{query_string}"
      else
        url
      end
    end

    def make_headers user_headers
      unless @cookies.empty?

        # Validate that the cookie names and values look sane. If you really
        # want to pass scary characters, just set the Cookie header directly.
        # RFC6265 is actually much more restrictive than we are.
        @cookies.each do |key, val|
          unless valid_cookie_key?(key)
            raise ArgumentError.new("Invalid cookie name: #{key.inspect}")
          end
          unless valid_cookie_value?(val)
            raise ArgumentError.new("Invalid cookie value: #{val.inspect}")
          end
        end

        user_headers[:cookie] = @cookies.map { |key, val| "#{key}=#{val}" }.sort.join('; ')
      end
      headers = stringify_headers(default_headers).merge(stringify_headers(user_headers))
      headers.merge!(@payload.headers) if @payload
      headers
    end

    # Do some sanity checks on cookie keys.
    #
    # Properly it should be a valid TOKEN per RFC 2616, but lots of servers are
    # more liberal.
    #
    # Disallow the empty string as well as keys containing control characters,
    # equals sign, semicolon, comma, or space.
    #
    def valid_cookie_key?(string)
      return false if string.empty?

      ! Regexp.new('[\x0-\x1f\x7f=;, ]').match(string)
    end

    # Validate cookie values. Rather than following RFC 6265, allow anything
    # but control characters, comma, and semicolon.
    def valid_cookie_value?(value)
      ! Regexp.new('[\x0-\x1f\x7f,;]').match(value)
    end

    def net_http_class
      if RestClient.proxy
        proxy_uri = URI.parse(RestClient.proxy)
        Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password)
      else
        Net::HTTP
      end
    end

    def net_http_request_class(method)
      Net::HTTP.const_get(method.to_s.capitalize)
    end

    def net_http_do_request(http, req, body=nil, &block)
      if body != nil && body.respond_to?(:read)
        req.body_stream = body
        return http.request(req, nil, &block)
      else
        return http.request(req, body, &block)
      end
    end

    def parse_url(url)
      url = "http://#{url}" unless url.match(/^http/)
      URI.parse(url)
    end

    def parse_url_with_auth(url)
      uri = parse_url(url)
      @user = CGI.unescape(uri.user) if uri.user
      @password = CGI.unescape(uri.password) if uri.password
      if !@user && !@password
        @user, @password = Netrc.read[uri.host]
      end
      uri
    end

    def process_payload(p=nil, parent_key=nil)
      unless p.is_a?(Hash)
        p
      else
        @headers[:content_type] ||= 'application/x-www-form-urlencoded'
        p.keys.map do |k|
          key = parent_key ? "#{parent_key}[#{k}]" : k
          if p[k].is_a? Hash
            process_payload(p[k], key)
          else
            value = parser.escape(p[k].to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
            "#{key}=#{value}"
          end
        end.join("&")
      end
    end

    # Return a certificate store that can be used to validate certificates with
    # the system certificate authorities. This will probably not do anything on
    # OS X, which monkey patches OpenSSL in terrible ways to insert its own
    # validation. On most *nix platforms, this will add the system certifcates
    # using OpenSSL::X509::Store#set_default_paths. On Windows, this will use
    # RestClient::Windows::RootCerts to look up the CAs trusted by the system.
    #
    # @return [OpenSSL::X509::Store]
    #
    def self.default_ssl_cert_store
      cert_store = OpenSSL::X509::Store.new
      cert_store.set_default_paths

      # set_default_paths() doesn't do anything on Windows, so look up
      # certificates using the win32 API.
      if RestClient::Platform.windows?
        RestClient::Windows::RootCerts.instance.to_a.uniq.each do |cert|
          begin
            cert_store.add_cert(cert)
          rescue OpenSSL::X509::StoreError => err
            # ignore duplicate certs
            raise unless err.message == 'cert already in hash table'
          end
        end
      end

      cert_store
    end

    def print_verify_callback_warnings
      warned = false
      if RestClient::Platform.mac_mri?
        warn('warning: ssl_verify_callback return code is ignored on OS X')
        warned = true
      end
      if RestClient::Platform.jruby?
        warn('warning: SSL verify_callback may not work correctly in jruby')
        warn('see https://github.com/jruby/jruby/issues/597')
        warned = true
      end
      warned
    end

    def transmit uri, req, payload, & block
      setup_credentials req

      net = net_http_class.new(uri.host, uri.port)
      net.use_ssl = uri.is_a?(URI::HTTPS)
      net.ssl_version = ssl_version if ssl_version
      net.ciphers = ssl_ciphers if ssl_ciphers

      net.verify_mode = verify_ssl

      net.cert = ssl_client_cert if ssl_client_cert
      net.key = ssl_client_key if ssl_client_key
      net.ca_file = ssl_ca_file if ssl_ca_file
      net.ca_path = ssl_ca_path if ssl_ca_path
      net.cert_store = ssl_cert_store if ssl_cert_store

      # We no longer rely on net.verify_callback for the main SSL verification
      # because it's not well supported on all platforms (see comments below).
      # But do allow users to set one if they want.
      if ssl_verify_callback
        net.verify_callback = ssl_verify_callback

        # Hilariously, jruby only calls the callback when cert_store is set to
        # something, so make sure to set one.
        # https://github.com/jruby/jruby/issues/597
        if RestClient::Platform.jruby?
          net.cert_store ||= OpenSSL::X509::Store.new
        end

        if ssl_verify_callback_warnings != false
          if print_verify_callback_warnings
            warn('pass :ssl_verify_callback_warnings => false to silence this')
          end
        end
      end

      if OpenSSL::SSL::VERIFY_PEER == OpenSSL::SSL::VERIFY_NONE
        warn('WARNING: OpenSSL::SSL::VERIFY_PEER == OpenSSL::SSL::VERIFY_NONE')
        warn('This dangerous monkey patch leaves you open to MITM attacks!')
        warn('Try passing :verify_ssl => false instead.')
      end

      if defined? @timeout
        if @timeout == -1
          warn 'To disable read timeouts, please set timeout to nil instead of -1'
          @timeout = nil
        end
        net.read_timeout = @timeout
      end
      if defined? @open_timeout
        if @open_timeout == -1
          warn 'To disable open timeouts, please set open_timeout to nil instead of -1'
          @open_timeout = nil
        end
        net.open_timeout = @open_timeout
      end

      RestClient.before_execution_procs.each do |before_proc|
        before_proc.call(req, args)
      end

      log_request


      net.start do |http|
        if @block_response
          net_http_do_request(http, req, payload ? payload.to_s : nil,
                              &@block_response)
        else
          res = net_http_do_request(http, req, payload ? payload.to_s : nil) \
            { |http_response| fetch_body(http_response) }
          log_response res
          process_result res, & block
        end
      end
    rescue EOFError
      raise RestClient::ServerBrokeConnection
    rescue Timeout::Error, Errno::ETIMEDOUT
      raise RestClient::RequestTimeout

    rescue OpenSSL::SSL::SSLError => error
      # TODO: deprecate and remove RestClient::SSLCertificateNotVerified and just
      # pass through OpenSSL::SSL::SSLError directly.
      #
      # Exceptions in verify_callback are ignored [1], and jruby doesn't support
      # it at all [2]. RestClient has to catch OpenSSL::SSL::SSLError and either
      # re-throw it as is, or throw SSLCertificateNotVerified based on the
      # contents of the message field of the original exception.
      #
      # The client has to handle OpenSSL::SSL::SSLError exceptions anyway, so
      # we shouldn't make them handle both OpenSSL and RestClient exceptions.
      #
      # [1] https://github.com/ruby/ruby/blob/89e70fe8e7/ext/openssl/ossl.c#L238
      # [2] https://github.com/jruby/jruby/issues/597

      if error.message.include?("certificate verify failed")
        raise SSLCertificateNotVerified.new(error.message)
      else
        raise error
      end
    end

    def setup_credentials(req)
      req.basic_auth(user, password) if user
    end

    def fetch_body(http_response)
      if @raw_response
        # Taken from Chef, which as in turn...
        # Stolen from http://www.ruby-forum.com/topic/166423
        # Kudos to _why!
        @tf = Tempfile.new("rest-client")
        @tf.binmode
        size, total = 0, http_response.header['Content-Length'].to_i
        http_response.read_body do |chunk|
          @tf.write chunk
          size += chunk.size
          if RestClient.log
            if size == 0
              RestClient.log << "%s %s done (0 length file)\n" % [@method, @url]
            elsif total == 0
              RestClient.log << "%s %s (zero content length)\n" % [@method, @url]
            else
              RestClient.log << "%s %s %d%% done (%d of %d)\n" % [@method, @url, (size * 100) / total, size, total]
            end
          end
        end
        @tf.close
        @tf
      else
        http_response.read_body
      end
      http_response
    end

    def process_result res, & block
      if @raw_response
        # We don't decode raw requests
        response = RawResponse.new(@tf, res, args, self)
      else
        response = Response.create(Request.decode(res['content-encoding'], res.body), res, args, self)
      end

      if block_given?
        block.call(response, self, res, & block)
      else
        response.return!(self, res, & block)
      end

    end

    def self.decode content_encoding, body
      if (!body) || body.empty?
        body
      elsif content_encoding == 'gzip'
        Zlib::GzipReader.new(StringIO.new(body)).read
      elsif content_encoding == 'deflate'
        begin
          Zlib::Inflate.new.inflate body
        rescue Zlib::DataError
          # No luck with Zlib decompression. Let's try with raw deflate,
          # like some broken web servers do.
          Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate body
        end
      else
        body
      end
    end

    def log_request
      return unless RestClient.log

      out = []
      sanitized_url = begin
        uri = URI.parse(url)
        uri.password = "REDACTED" if uri.password
        uri.to_s
      rescue URI::InvalidURIError
        # An attacker may be able to manipulate the URL to be
        # invalid, which could force discloure of a password if
        # we show any of the un-parsed URL here.
        "[invalid uri]"
      end

      out << "RestClient.#{method} #{sanitized_url.inspect}"
      out << payload.short_inspect if payload
      out << processed_headers.to_a.sort.map { |(k, v)| [k.inspect, v.inspect].join("=>") }.join(", ")
      RestClient.log << out.join(', ') + "\n"
    end

    def log_response res
      return unless RestClient.log

      size = if @raw_response
               File.size(@tf.path)
             else
               res.body.nil? ? 0 : res.body.size
             end

      RestClient.log << "# => #{res.code} #{res.class.to_s.gsub(/^Net::HTTP/, '')} | #{(res['Content-type'] || '').gsub(/;.*$/, '')} #{size} bytes\n"
    end

    # Return a hash of headers whose keys are capitalized strings
    def stringify_headers headers
      headers.inject({}) do |result, (key, value)|
        if key.is_a? Symbol
          key = key.to_s.split(/_/).map { |w| w.capitalize }.join('-')
        end
        if 'CONTENT-TYPE' == key.upcase
          result[key] = maybe_convert_extension(value.to_s)
        elsif 'ACCEPT' == key.upcase
          # Accept can be composed of several comma-separated values
          if value.is_a? Array
            target_values = value
          else
            target_values = value.to_s.split ','
          end
          result[key] = target_values.map { |ext|
            maybe_convert_extension(ext.to_s.strip)
          }.join(', ')
        else
          result[key] = value.to_s
        end
        result
      end
    end

    def default_headers
      {:accept => '*/*; q=0.5, application/xml', :accept_encoding => 'gzip, deflate'}
    end

    private

    def parser
      URI.const_defined?(:Parser) ? URI::Parser.new : URI
    end

    # Given a MIME type or file extension, return either a MIME type or, if
    # none is found, the input unchanged.
    #
    #     >> maybe_convert_extension('json')
    #     => 'application/json'
    #
    #     >> maybe_convert_extension('unknown')
    #     => 'unknown'
    #
    #     >> maybe_convert_extension('application/xml')
    #     => 'application/xml'
    #
    # @param ext [String]
    #
    # @return [String]
    #
    def maybe_convert_extension(ext)
      unless ext =~ /\A[a-zA-Z0-9_@-]+\z/
        # Don't look up strings unless they look like they could be a file
        # extension known to mime-types.
        #
        # There currently isn't any API public way to look up extensions
        # directly out of MIME::Types, but the type_for() method only strips
        # off after a period anyway.
        return ext
      end

      types = MIME::Types.type_for(ext)
      if types.empty?
        ext
      else
        types.first.content_type
      end
    end
  end
end
