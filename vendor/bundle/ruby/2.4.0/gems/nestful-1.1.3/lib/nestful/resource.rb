require 'uri'

module Nestful
  class Resource
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

    def self.defaults(value = nil)
      @defaults = value if value
      return @defaults if defined?(@defaults) && @defaults
      superclass.respond_to?(:defaults) ? superclass.defaults : {}
    end

    class << self
      alias_method :endpoint=, :endpoint
      alias_method :path=, :path
      alias_method :defaults=, :defaults
      alias_method :options, :defaults
      alias_method :options=, :defaults
    end

    def self.url
      URI.join(endpoint.to_s, path.to_s).to_s
    end

    def self.uri(*parts)
      # If an absolute URI already
      if (uri = parts.first) && uri.is_a?(URI)
        return uri if uri.host
      end

      URI.parse(Helpers.to_path(url, *parts))
    end

    def self.get(action = '', params = {}, options = {})
      request(uri(action), options.merge(:method => :get, :params => params))
    end

    def self.put(action = '', params = {}, options = {})
      request(uri(action), options.merge(:method => :put, :params => params))
    end

    def self.post(action = '', params = {}, options = {})
      request(uri(action), options.merge(:method => :post, :params => params))
    end

    def self.delete(action = '', params = {}, options = {})
      request(uri(action), options.merge(:method => :delete, :params => params))
    end

    def self.request(url, options = {})
      Request.new(url, Helpers.deep_merge(self.options, options)).execute
    end

    def self.all(*args)
      self.new(get('', *args))
    end

    def self.find(id)
      self.new(get(id))
    end

    def self.new(attributes = {})
      if attributes.is_a?(Array)
        attributes.map {|set| super(set) }
      else
        super
      end
    end

    attr_reader :attributes

    def initialize(attributes = {})
      @attributes = {}
      load(attributes)
    end

    def get(action = '', *args)
      self.class.get(path(action), *args)
    end

    def put(action = '', *args)
      self.class.put(path(action), *args)
    end

    def post(action = '', *args)
      self.class.post(path(action), *args)
    end

    def delete(action = '', *args)
      self.class.delete(path(action), *args)
    end

    def path(*parts)
      Helpers.to_path(self.id, *parts)
    end

    def id #:nodoc:
      self['id']
    end

    def type #:nodoc:
      self['type']
    end

    def [](key)
      attributes[key]
    end

    def []=(key,value)
      attributes[key] = value
    end

    def to_hash
      attributes.dup
    end

    def as_json(*)
      to_hash
    end

    def to_json(*)
      as_json.to_json
    end

    def load(attributes = {})
      attributes.to_hash.each do |key, value|
        send("#{key}=", value)
      end
    end

    def ==(other)
      other.equal?(self) ||
        (other.instance_of?(self.class) && other.attributes == attributes)
    end

    # Tests for equality (delegates to ==).
    def eql?(other)
      self == other
    end

    def hash
      attributes.hash
    end

    alias_method :respond_to_without_attributes?, :respond_to?

    def respond_to?(method, include_priv = false)
      method_name = method.to_s
      if attributes.nil?
        super
      elsif attributes.include?(method_name.sub(/[=\?]\Z/, ''))
        true
      else
        super
      end
    end

    protected

    def method_missing(method_symbol, *arguments) #:nodoc:
      method_name = method_symbol.to_s

      if method_name =~ /(=|\?)$/
        case $1
        when "="
          attributes[$`] = arguments.first
        when "?"
          attributes[$`]
        end
      else
        return attributes[method_name] if attributes.include?(method_name)
        super
      end
    end
  end
end
