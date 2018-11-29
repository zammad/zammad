require 'uri'

module Clearbit
  class Resource < Mash
    def self.endpoint(value = nil)
      @endpoint = value if value
      return @endpoint if @endpoint
      superclass.respond_to?(:endpoint) ? superclass.endpoint : nil
    end

    def self.path(value = nil)
      @path = value if value
      return @path if @path
      superclass.respond_to?(:path) ? superclass.path : nil
    end

    def self.options(value = nil)
      @options ||= {}
      @options.merge!(value) if value

      if superclass <= Resource && superclass.respond_to?(:options)
        Nestful::Helpers.deep_merge(superclass.options, @options)
      else
        @options
      end
    end

    class << self
      alias_method :endpoint=, :endpoint
      alias_method :path=, :path
      alias_method :options=, :options
      alias_method :add_options, :options
    end

    def self.url(options = {})
      URI.join(endpoint.to_s, path.to_s).to_s
    end

    def self.uri(*parts)
      # If an absolute URI already
      if (uri = parts.first) && uri.is_a?(URI)
        return uri if uri.host
      end

      value = Nestful::Helpers.to_path(url, *parts)

      URI.parse(value)
    end

    OPTION_KEYS = %i{
      params key headers stream
      proxy user password auth_type
      timeout ssl_options request
    }

    def self.parse_values(values)
      params  = values.reject {|k,_| OPTION_KEYS.include?(k) }
      options = values.select {|k,_| OPTION_KEYS.include?(k) }

      if request_options = options.delete(:request)
        options.merge!(request_options)
      end

      if key = options.delete(:key)
        options.merge!(
          auth_type: :bearer,
          password:  key
        )
      end

      [params, options]
    end

    def self.get(action = '', values = {})
      params, options = parse_values(values)

      request(
        uri(action),
        options.merge(method: :get, params: params))
    end

    def self.put(action = '', values = {})
      params, options = parse_values(values)

      request(
        uri(action),
        options.merge(method: :put, params: params, format: :json))
    end

    def self.post(action = '', values = {})
      params, options = parse_values(values)

      request(
        uri(action),
        options.merge(method: :post, params: params, format: :json))
    end

    def self.delete(action = '', values = {})
      params, options = parse_values(values)

      request(
        uri(action),
        options.merge(method: :delete, params: params))
    end

    def self.request(uri, options = {})
      options = Nestful::Helpers.deep_merge(self.options, options)

      if options[:stream]
        uri.host = uri.host.gsub('.clearbit.com', '-stream.clearbit.com')
      end

      response = Nestful::Request.new(
        uri, options
      ).execute

      if notice = response.headers['X-API-Warn']
        Kernel.warn notice
      end

      response
    end

    def uri(*parts)
      self.class.uri(*[id, *parts].compact)
    end
  end
end
