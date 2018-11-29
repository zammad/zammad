module Nestful
  class Error < StandardError
    attr_reader :request

    def initialize(request = nil, message = nil)
      super(message)
      @request = request
    end
  end

  ConnectionError = Error
  RequestError = Error

  class ResponseError < Error
    attr_reader :response

    def initialize(request, response, message = nil)
      super(request, message)
      @response = response
    end

    def to_s
      message = "Failed."
      message << "  Response code = #{response.code}." if response.respond_to?(:code)
      message << "  Response message = #{response.message}." if response.respond_to?(:message)

      if response.respond_to?(:body)
        # Error messages need to be in UTF-8
        body = response.body.dup.to_s
        body = body.encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => '?')
        body = body[0..255]
        message << "  Response Body = #{body}."
      end

      message
    end
  end

  # Raised when a Timeout::Error occurs.
  class TimeoutError < RequestError
  end

  # Raised when a OpenSSL::SSL::SSLError occurs.
  class SSLError < RequestError
  end

  class ErrnoError < RequestError
  end

  class ZlibError < RequestError
  end

  # 3xx Redirection
  class Redirection < ResponseError # :nodoc:
    def to_s; response['Location'] ? "#{super} => #{response['Location']}" : super; end
  end

  class RedirectionLoop < ResponseError # :nodoc:
    def to_s; response['Location'] ? "#{super} => #{response['Location']}" : super; end
  end

  # 4xx Client Error
  class ClientError < ResponseError; end # :nodoc:

  # 400 Bad Request
  class BadRequest < ClientError; end # :nodoc

  # 401 Unauthorized
  class UnauthorizedAccess < ClientError; end # :nodoc

  # 403 Forbidden
  class ForbiddenAccess < ClientError; end # :nodoc

  # 404 Not Found
  class ResourceNotFound < ClientError; end # :nodoc:

  # 409 Conflict
  class ResourceConflict < ClientError; end # :nodoc:

  # 410 Gone
  class ResourceGone < ClientError; end # :nodoc:

  # 422 Invalid
  class ResourceInvalid < ClientError; end # :nodoc:

  # 5xx Server Error
  class ServerError < ResponseError; end # :nodoc:

  # 405 Method Not Allowed
  class MethodNotAllowed < ClientError # :nodoc:
    def allowed_methods
      @response['Allow'].split(',').map { |verb| verb.strip.downcase.to_sym }
    end
  end
end
