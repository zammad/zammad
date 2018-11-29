require 'net/https'
require 'uri'

module Nestful
  class Connection
    UriParser = URI.const_defined?(:Parser) ? URI::Parser.new : URI

    attr_accessor :timeout, :ssl_options
    attr_reader :endpoint, :proxy

    # The +endpoint+ parameter is required and will set the +endpoint+
    # attribute to the URI for the remote resource service.
    def initialize(endpoint, options = {})
      self.endpoint = endpoint

      options.each do |key, value|
        self.send("#{key}=", value) unless value.nil?
      end
    end

    # Set URI for remote service.
    def endpoint=(endpoint)
      @endpoint = endpoint.is_a?(URI) ? endpoint : UriParser.parse(endpoint)
    end

    # Set the proxy for remote service.
    def proxy=(proxy)
      @proxy = proxy.is_a?(URI) ? proxy : UriParser.parse(proxy)
    end

    def get(path, headers = {}, &block)
      request(:get, path, headers, &block)
    end

    def delete(path, headers = {}, &block)
      request(:delete, path, headers, &block)
    end

    def head(path, headers = {}, &block)
      request(:head, path, headers, &block)
    end

    def put(path, body = '', headers = {}, &block)
      request(:put, path, body, headers, &block)
    end

    def patch(path, body = '', headers = {}, &block)
      request(:patch, path, body, headers, &block)
    end

    def post(path, body = '', headers = {}, &block)
      request(:post, path, body, headers, &block)
    end

    protected

    def request=(request)
      @request = request
    end

    # Makes a request to the remote service.
    def request(method, path, *arguments)
      response = http.send(method, path, *arguments)
      response.uri = URI.join(endpoint, path)

      handle_response(response)

    rescue Timeout::Error, Net::OpenTimeout => e
      raise TimeoutError.new(@request, e.message)
    rescue OpenSSL::SSL::SSLError => e
      raise SSLError.new(@request, e.message)
    rescue SocketError,
           EOFError,
           Net::HTTPBadResponse,
           Net::HTTPHeaderSyntaxError,
           Net::HTTPServerException,
           Net::ProtocolError,
           Errno::ECONNABORTED,
           Errno::ECONNREFUSED,
           Errno::ECONNRESET,
           Errno::ETIMEDOUT,
           Errno::ENETUNREACH,
           Errno::EHOSTUNREACH,
           Errno::EINVAL,
           Errno::ENOPROTOOPT => e
      raise ErrnoError.new(@request, e.message)
    rescue Zlib::DataError,
           Zlib::BufError => e
      raise ZlibError.new(@request, e.message)
    end

    # Handles response and error codes from the remote service.
    def handle_response(response)
      case response.code.to_i
      when 200...299
        response
      when 300..399
        raise Redirection.new(@request, response)
      when 400
        raise BadRequest.new(@request, response)
      when 401
        raise UnauthorizedAccess.new(@request, response)
      when 403
        raise ForbiddenAccess.new(@request, response)
      when 404
        raise ResourceNotFound.new(@request, response)
      when 405
        raise MethodNotAllowed.new(@request, response)
      when 409
        raise ResourceConflict.new(@request, response)
      when 410
        raise ResourceGone.new(@request, response)
      when 422
        raise ResourceInvalid.new(@request, response)
      when 401...500
        raise ClientError.new(@request, response)
      when 500...600
        raise ServerError.new(@request, response)
      else
        raise ResponseError.new(
          @request, response, "Unknown response code: #{response.code}"
        )
      end
    end

    # Creates new Net::HTTP instance for communication with the
    # remote service and resources.
    def http
      configure_http(new_http)
    end

    def new_http
      if proxy
        Net::HTTP.new(endpoint.host, endpoint.port,
                      proxy.host, proxy.port,
                      proxy.user, proxy.password)
      else
        Net::HTTP.new(endpoint.host, endpoint.port)
      end
    end

    def configure_http(http)
      http = apply_ssl_options(http)

      # Net::HTTP timeouts default to 60 seconds.
      if timeout
        http.open_timeout = timeout
        http.read_timeout = timeout
      end

      http
    end

    def apply_ssl_options(http)
      return http unless endpoint.is_a?(URI::HTTPS)

      http.use_ssl     = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      return http unless ssl_options

      ssl_options.each do |key, value|
        http.send("#{key}=", value)
      end

      http
    end
  end
end
