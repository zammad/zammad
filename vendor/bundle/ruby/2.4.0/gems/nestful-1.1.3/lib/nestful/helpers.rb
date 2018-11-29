require 'uri'

module Nestful
  module Helpers extend self
    def to_path(*params)
      params.map(&:to_s).reject(&:empty?) * '/'
    end

    def camelize(value)
      value.to_s.split('_').map {|w| w.capitalize }.join
    end

    def deep_merge(hash, other_hash)
      hash.merge(other_hash) do |key, oldval, newval|
        oldval = oldval.to_hash if oldval.respond_to?(:to_hash)
        newval = newval.to_hash if newval.respond_to?(:to_hash)
        oldval.class.to_s == 'Hash' && newval.class.to_s == 'Hash' ? deep_merge(oldval, newval) : newval
      end
    end

    # Stolen from Rack:

    DEFAULT_SEP = /[&;] */n

    def to_param(value, prefix = nil)
      case value
      when Array
        value.map { |v|
          to_param(v, "#{prefix}[]")
        }.join("&")
      when Hash
        value.map { |k, v|
          to_param(v, prefix ? "#{prefix}[#{escape(k)}]" : escape(k))
        }.join("&")
      else
        raise ArgumentError, "value must be a Hash" if prefix.nil?
        "#{prefix}=#{escape(value)}"
      end
    end

    def to_url_param(value, prefix = nil)
      case value
      when Array
        value.map { |v|
          to_url_param(v, "#{prefix}[]")
        }.join("&")
      when Hash
        value.map { |k, v|
          to_url_param(v, prefix ? "#{prefix}[#{uri_escape(k)}]" : uri_escape(k))
        }.join("&")
      else
        raise ArgumentError, "value must be a Hash" if prefix.nil?
        "#{prefix}=#{uri_escape(value)}"
      end
    end

    def from_param(qs, d = nil)
      params = {}

      (qs || '').split(d ? /[#{d}] */n : DEFAULT_SEP).each do |p|
        k, v = p.split('=', 2).map { |s| unescape(s) }

        normalize_params(params, k, v)
      end

      params
    end

    def escape(s)
      URI.encode_www_form_component(s.to_s)
    end

    ESCAPE_RE = /[^a-zA-Z0-9 .~_-]/

    def uri_escape(s)
      s.to_s.gsub(ESCAPE_RE) {|match|
        '%' + match.unpack('H2' * match.bytesize).join('%').upcase
      }.tr(' ', '+')
    end

    if defined?(::Encoding)
      def unescape(s, encoding = Encoding::UTF_8)
        URI.decode_www_form_component(s, encoding)
      end
    else
      def unescape(s, encoding = nil)
        URI.decode_www_form_component(s, encoding)
      end
    end

    protected

    def normalize_params(params, name, v = nil)
      name =~ %r(\A[\[\]]*([^\[\]]+)\]*)
      k = $1 || ''
      after = $' || ''

      return if k.empty?

      if after == ""
        params[k] = v
      elsif after == "[]"
        params[k] ||= []
        raise TypeError, "expected Array (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Array)
        params[k] << v
      elsif after =~ %r(^\[\]\[([^\[\]]+)\]$) || after =~ %r(^\[\](.+)$)
        child_key = $1
        params[k] ||= []
        raise TypeError, "expected Array (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Array)
        if params[k].last.kind_of?(Hash) && !params[k].last.key?(child_key)
          normalize_params(params[k].last, child_key, v)
        else
          params[k] << normalize_params(params.class.new, child_key, v)
        end
      else
        params[k] ||= params.class.new
        raise TypeError, "expected Hash (got #{params[k].class.name}) for param `#{k}'" unless params[k].kind_of?(Hash)
        params[k] = normalize_params(params[k], after, v)
      end

      return params
    end
  end
end
