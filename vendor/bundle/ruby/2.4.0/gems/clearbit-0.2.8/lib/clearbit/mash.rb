module Clearbit
  class Mash < Hash
    def self.new(value = nil, *args)
      if value.respond_to?(:each) &&
        !value.respond_to?(:each_pair)
        value.map {|v| super(v) }
      else
        super
      end
    end

    alias_method :to_s, :inspect

    def initialize(source_hash = nil, default = nil, &blk)
      deep_update(source_hash.to_hash) if source_hash
      default ? super(default) : super(&blk)
    end

    class << self; alias [] new; end

    def id #:nodoc:
      self['id']
    end

    def type #:nodoc:
      self['type']
    end

    alias_method :regular_reader, :[]
    alias_method :regular_writer, :[]=

    # Retrieves an attribute set in the Mash. Will convert
    # any key passed in to a string before retrieving.
    def custom_reader(key)
      value = regular_reader(convert_key(key))
      yield value if block_given?
      value
    end

    # Sets an attribute in the Mash. Key will be converted to
    # a string before it is set, and Hashes will be converted
    # into Mashes for nesting purposes.
    def custom_writer(key,value) #:nodoc:
      regular_writer(convert_key(key), convert_value(value))
    end

    alias_method :[], :custom_reader
    alias_method :[]=, :custom_writer

    # This is the bang method reader, it will return a new Mash
    # if there isn't a value already assigned to the key requested.
    def initializing_reader(key)
      ck = convert_key(key)
      regular_writer(ck, self.class.new) unless key?(ck)
      regular_reader(ck)
    end

    # This is the under bang method reader, it will return a temporary new Mash
    # if there isn't a value already assigned to the key requested.
    def underbang_reader(key)
      ck = convert_key(key)
      if key?(ck)
        regular_reader(ck)
      else
        self.class.new
      end
    end

    def fetch(key, *args)
      super(convert_key(key), *args)
    end

    def delete(key)
      super(convert_key(key))
    end

    alias_method :regular_dup, :dup
    # Duplicates the current mash as a new mash.
    def dup
      self.class.new(self, self.default)
    end

    def key?(key)
      super(convert_key(key))
    end
    alias_method :has_key?, :key?
    alias_method :include?, :key?
    alias_method :member?, :key?

    # Performs a deep_update on a duplicate of the
    # current mash.
    def deep_merge(other_hash, &blk)
      dup.deep_update(other_hash, &blk)
    end
    alias_method :merge, :deep_merge

    # Recursively merges this mash with the passed
    # in hash, merging each hash in the hierarchy.
    def deep_update(other_hash, &blk)
      other_hash.each_pair do |k,v|
        key = convert_key(k)
        if regular_reader(key).is_a?(Mash) and v.is_a?(::Hash)
          custom_reader(key).deep_update(v, &blk)
        else
          value = convert_value(v, true)
          value = blk.call(key, self[k], value) if blk
          custom_writer(key, value)
        end
      end
      self
    end
    alias_method :deep_merge!, :deep_update
    alias_method :update, :deep_update
    alias_method :merge!, :update

    # Performs a shallow_update on a duplicate of the current mash
    def shallow_merge(other_hash)
      dup.shallow_update(other_hash)
    end

    # Merges (non-recursively) the hash from the argument,
    # changing the receiving hash
    def shallow_update(other_hash)
      other_hash.each_pair do |k,v|
        regular_writer(convert_key(k), convert_value(v, true))
      end
      self
    end

    def replace(other_hash)
      (keys - other_hash.keys).each { |key| delete(key) }
      other_hash.each { |key, value| self[key] = value }
      self
    end

    # Will return true if the Mash has had a key
    # set in addition to normal respond_to? functionality.
    def respond_to?(method_name, include_private=false)
      camelized_name = camelize(method_name.to_s)

      if key?(method_name) ||
          key?(camelized_name) ||
            method_name.to_s.slice(/[=?!_]\Z/)
        return true
      end

      super
    end

    def method_missing(method_name, *args, &blk)
      return self.[](method_name, &blk) if key?(method_name)

      camelized_name = camelize(method_name.to_s)

      if key?(camelized_name)
        return self.[](camelized_name, &blk)
      end

      match = method_name.to_s.match(/(.*?)([?=!_]?)$/)

      case match[2]
      when "="
        self[match[1]] = args.first
      when "?"
        !!self[match[1]]
      when "!"
        initializing_reader(match[1])
      when "_"
        underbang_reader(match[1])
      else
        default(method_name, *args, &blk)
      end
    end

    protected

    def camelize(string)
      string = string.to_s
      string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { $&.downcase }
      string.gsub(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }.gsub('/', '::')
    end

    def convert_key(key) #:nodoc:
      key.to_s
    end

    def convert_value(val, duping=false) #:nodoc:
      case val
        when self.class
          val.dup
        when ::Hash
          val = val.dup if duping
          Mash.new(val)
        when ::Array
          val.map {|e| convert_value(e) }
        else
          val
      end
    end
  end
end
