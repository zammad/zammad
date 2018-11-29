module Nestful
  class Endpoint
    def self.[](url)
      self.new(url)
    end

    attr_reader :url

    def initialize(url, options = {})
      @url     = url
      @options = options
    end

    def [](suburl)
      return self if suburl.nil?
      suburl = suburl.to_s
      base   = url
      base  += "/" unless base =~ /\/$/
      self.class.new(URI.join(base, suburl).to_s, @options)
    end

    def get(params = {}, options = {})
      request(options.merge(:method => :get, :params => params))
    end

    def put(params = {}, options = {})
      request(options.merge(:method => :put, :params => params))
    end

    def post(params = {}, options = {})
      request(options.merge(:method => :post, :params => params))
    end

    def delete(params = {}, options = {})
      request(options.merge(:method => :delete, :params => params))
    end

    def request(options = {})
      Request.new(url, options.merge(@options)).execute
    end
  end
end
