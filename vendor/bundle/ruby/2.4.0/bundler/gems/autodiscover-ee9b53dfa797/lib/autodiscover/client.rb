module Autodiscover
  class Client
    DEFAULT_HTTP_TIMEOUT = 10
    attr_reader :domain, :email, :http

    # @param email [String] An e-mail to use for autodiscovery. It will be
    #   used as the default username.
    # @param password [String]
    # @param username [String] An optional username if you want to authenticate
    #   with something other than the e-mail. For instance DOMAIN\user
    # @param domain [String] An optional domain to provide as an override for
    #   the one parsed from the e-mail.
    def initialize(email:, password:, username: nil, domain: nil, connect_timeout: DEFAULT_HTTP_TIMEOUT)
      @email = email
      @domain = domain || @email.split("@").last
      @http = HTTPClient.new
      @http.connect_timeout = connect_timeout if connect_timeout
      @username = username || email
      @http.set_auth(nil, @username, password)
    end

    # @param type [Symbol] The type of response. Right now this is just :pox
    # @param [Hash] **options
    def autodiscover(type: :pox, **options)
      case type
      when :pox
        PoxRequest.new(self, **options).autodiscover
      else
        raise Autodiscover::ArgumentError, "Not a valid autodiscover type (#{type})."
      end
    end

  end
end
