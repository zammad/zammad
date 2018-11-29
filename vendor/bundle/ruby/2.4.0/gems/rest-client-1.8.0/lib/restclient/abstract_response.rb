require 'cgi'
require 'http-cookie'

module RestClient

  module AbstractResponse

    attr_reader :net_http_res, :args, :request

    # HTTP status code
    def code
      @code ||= @net_http_res.code.to_i
    end

    # A hash of the headers, beautified with symbols and underscores.
    # e.g. "Content-type" will become :content_type.
    def headers
      @headers ||= AbstractResponse.beautify_headers(@net_http_res.to_hash)
    end

    # The raw headers.
    def raw_headers
      @raw_headers ||= @net_http_res.to_hash
    end

    def response_set_vars(net_http_res, args, request)
      @net_http_res = net_http_res
      @args = args
      @request = request
    end

    # Hash of cookies extracted from response headers
    def cookies
      hash = {}

      cookie_jar.cookies.each do |cookie|
        hash[cookie.name] = cookie.value
      end

      hash
    end

    # Cookie jar extracted from response headers.
    #
    # @return [HTTP::CookieJar]
    #
    def cookie_jar
      return @cookie_jar if @cookie_jar

      jar = HTTP::CookieJar.new
      headers.fetch(:set_cookie, []).each do |cookie|
        jar.parse(cookie, @request.url)
      end

      @cookie_jar = jar
    end

    # Return the default behavior corresponding to the response code:
    # the response itself for code in 200..206, redirection for 301, 302 and 307 in get and head cases, redirection for 303 and an exception in other cases
    def return! request = nil, result = nil, & block
      if (200..207).include? code
        self
      elsif [301, 302, 307].include? code
        unless [:get, :head].include? args[:method]
          raise Exceptions::EXCEPTIONS_MAP[code].new(self, code)
        else
          follow_redirection(request, result, & block)
        end
      elsif code == 303
        args[:method] = :get
        args.delete :payload
        follow_redirection(request, result, & block)
      elsif Exceptions::EXCEPTIONS_MAP[code]
        raise Exceptions::EXCEPTIONS_MAP[code].new(self, code)
      else
        raise RequestFailed.new(self, code)
      end
    end

    def to_i
      code
    end

    def description
      "#{code} #{STATUSES[code]} | #{(headers[:content_type] || '').gsub(/;.*$/, '')} #{size} bytes\n"
    end

    # Follow a redirection
    def follow_redirection request = nil, result = nil, & block
      new_args = @args.dup

      url = headers[:location]
      if url !~ /^http/
        url = URI.parse(request.url).merge(url).to_s
      end
      new_args[:url] = url
      if request
        if request.max_redirects == 0
          raise MaxRedirectsReached
        end
        new_args[:password] = request.password
        new_args[:user] = request.user
        new_args[:headers] = request.headers
        new_args[:max_redirects] = request.max_redirects - 1

        # TODO: figure out what to do with original :cookie, :cookies values
        new_args[:headers]['Cookie'] = HTTP::Cookie.cookie_value(
          cookie_jar.cookies(new_args.fetch(:url)))
      end

      Request.execute(new_args, &block)
    end

    def self.beautify_headers(headers)
      headers.inject({}) do |out, (key, value)|
        out[key.gsub(/-/, '_').downcase.to_sym] = %w{ set-cookie }.include?(key.downcase) ? value : value.first
        out
      end
    end

    private

    # Parse a cookie value and return its content in an Hash
    def parse_cookie cookie_content
      out = {}
      CGI::Cookie::parse(cookie_content).each do |key, cookie|
        unless ['expires', 'path'].include? key
          out[CGI::escape(key)] = cookie.value[0] ? (CGI::escape(cookie.value[0]) || '') : ''
        end
      end
      out
    end
  end

end
