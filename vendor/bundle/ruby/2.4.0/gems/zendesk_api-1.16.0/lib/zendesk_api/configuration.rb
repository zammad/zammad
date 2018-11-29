module ZendeskAPI
  # Holds the configuration options for the client and connection
  class Configuration
    # @return [String] The basic auth username.
    attr_accessor :username

    # @return [String] The basic auth password.
    attr_accessor :password

    # @return [String] The basic auth token.
    attr_accessor :token

    # @return [String] The API url. Must be https unless {#allow_http} is set.
    attr_accessor :url

    # @return [Boolean] Whether to attempt to retry when rate-limited (http status: 429).
    attr_accessor :retry

    # @return [Logger] Logger to use when logging requests.
    attr_accessor :logger

    # @return [Hash] Client configurations (eg ssh config) to pass to Faraday
    attr_accessor :client_options

    # @return [Symbol] Faraday adapter
    attr_accessor :adapter

    # @return [Boolean] Whether to allow non-HTTPS connections for development purposes.
    attr_accessor :allow_http

    # @return [String] OAuth2 access_token
    attr_accessor :access_token

    attr_accessor :url_based_access_token

    # Use this cache instead of default ZendeskAPI::LRUCache.new
    # - must respond to read/write/fetch e.g. ActiveSupport::Cache::MemoryStore.new)
    # - pass false to disable caching
    # @return [ZendeskAPI::LRUCache]
    attr_accessor :cache

    def initialize
      @client_options = {}

      self.cache = ZendeskAPI::LRUCache.new(1000)
    end

    # Sets accept and user_agent headers, and url.
    #
    # @return [Hash] Faraday-formatted hash of options.
    def options
      {
        :headers => {
          :accept => 'application/json',
          :accept_encoding => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          :user_agent => "ZendeskAPI Ruby #{ZendeskAPI::VERSION}"
        },
        :request => {
          :open_timeout => 10
        },
        :url => @url
      }.merge(client_options)
    end
  end
end
