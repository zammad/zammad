module Ref
  # Abstract base class for WeakKeyMap and SoftKeyMap.
  #
  # The classes behave similar to Hashes, but the keys in the map are not strong references
  # and can be reclaimed by the garbage collector at any time. When a key is reclaimed, the
  # map entry will be removed.
  class AbstractReferenceKeyMap
    class << self
      def reference_class=(klass) #:nodoc:
        @reference_class = klass
      end

      def reference_class #:nodoc:
        raise NotImplementedError.new("#{name} is an abstract class and cannot be instantiated") unless @reference_class
        @reference_class
      end
    end

    # Create a new map. Values added to the hash will be cleaned up by the garbage
    # collector if there are no other reference except in the map.
    def initialize
      @values = {}
      @references_to_keys_map = {}
      @lock = Monitor.new
      @reference_cleanup = lambda{|object_id| remove_reference_to(object_id)}
    end

    # Get a value from the map by key. If the value has been reclaimed by the garbage
    # collector, this will return nil.
    def [](key)
      @lock.synchronize do
        rkey = ref_key(key)
        @values[rkey] if rkey
      end
    end

    alias_method :get, :[]

    # Add a key/value to the map.
    def []=(key, value)
      ObjectSpace.define_finalizer(key, @reference_cleanup)
      @lock.synchronize do
        @references_to_keys_map[key.__id__] = self.class.reference_class.new(key)
        @values[key.__id__] = value
      end
    end

    alias_method :put, :[]=

    # Remove the value associated with the key from the map.
    def delete(key)
      @lock.synchronize do
        rkey = ref_key(key)
        if rkey
          @references_to_keys_map.delete(rkey)
          @values.delete(rkey)
        else
          nil
        end
      end
    end

    # Get an array of keys that have not yet been garbage collected.
    def keys
      @values.keys.collect{|rkey| @references_to_keys_map[rkey].object}.compact
    end

    # Turn the map into an arry of [key, value] entries.
    def to_a
      array = []
      each{|k,v| array << [k, v]}
      array
    end

    # Returns a hash containing the names and values for the struct’s members.
    def to_h
      hash = {}
      each{|k,v| hash[k] = v}
      hash
    end

    # Iterate through all the key/value pairs in the map that have not been reclaimed
    # by the garbage collector.
    def each
      @references_to_keys_map.each do |rkey, ref|
        key = ref.object
        yield(key, @values[rkey]) if key
      end
    end

    # Clear the map of all key/value pairs.
    def clear
      @lock.synchronize do
        @values.clear
        @references_to_keys_map.clear
      end
    end

    # Returns a new struct containing the contents of `other` and the contents
    # of `self`. If no block is specified, the value for entries with duplicate
    # keys will be that of `other`. Otherwise the value for each duplicate key
    # is determined by calling the block with the key, its value in `self` and
    # its value in `other`.
    def merge(other_hash, &block)
      to_h.merge(other_hash, &block).reduce(self.class.new) do |map, pair|
        map[pair.first] = pair.last
        map
      end
    end

    # Merge the values from another hash into this map.
    def merge!(other_hash)
      @lock.synchronize do
        other_hash.each { |key, value| self[key] = value }
      end
    end

    # The number of entries in the map
    def size
      @references_to_keys_map.count do |_, ref|
        ref.object
      end
    end

    alias_method :length, :size

    # True if there are entries that exist in the map
    def empty?
      @references_to_keys_map.each do |_, ref|
        return false if ref.object
      end
      true
    end

    def inspect
      live_entries = {}
      each do |key, value|
        live_entries[key] = value
      end
      live_entries.inspect
    end

    private

    def ref_key (key)
      ref = @references_to_keys_map[key.__id__]
      if ref && ref.object
        ref.referenced_object_id
      else
        nil
      end
    end

    def remove_reference_to(object_id)
      @lock.synchronize do
        @references_to_keys_map.delete(object_id)
        @values.delete(object_id)
      end
    end
  end
end
