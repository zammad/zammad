module Ref
  # Abstract base class for WeakValueMap and SoftValueMap.
  #
  # The classes behave similar to Hashes, but the values in the map are not strong references
  # and can be reclaimed by the garbage collector at any time. When a value is reclaimed, the
  # map entry will be removed.
  class AbstractReferenceValueMap
    class << self
      def reference_class=(klass) #:nodoc:
        @reference_class = klass
      end

      def reference_class #:nodoc:
        raise NotImplementedError.new("#{name} is an abstract class and cannot be instantiated") unless @reference_class
        @reference_class
      end
    end

    # Create a new map. Values added to the map will be cleaned up by the garbage
    # collector if there are no other reference except in the map.
    def initialize
      @references = {}
      @references_to_keys_map = {}
      @lock = Monitor.new
      @reference_cleanup = lambda{|object_id| remove_reference_to(object_id)}
    end

    # Get a value from the map by key. If the value has been reclaimed by the garbage
    # collector, this will return nil.
    def [](key)
      @lock.synchronize do
        ref = @references[key]
        value = ref.object if ref
        value
      end
    end

    alias_method :get, :[]

    # Add a key/value to the map.
    def []=(key, value)
      ObjectSpace.define_finalizer(value, @reference_cleanup)
      key = key.dup if key.is_a?(String)
      @lock.synchronize do
        @references[key] = self.class.reference_class.new(value)
        keys_for_id = @references_to_keys_map[value.__id__]
        unless keys_for_id
          keys_for_id = []
          @references_to_keys_map[value.__id__] = keys_for_id
        end
        keys_for_id << key
      end
      value
    end

    alias_method :put, :[]=

    # Remove the entry associated with the key from the map.
    def delete(key)
      ref = @references.delete(key)
      if ref
        keys_to_id = @references_to_keys_map[ref.referenced_object_id]
        if keys_to_id
          keys_to_id.delete(key)
          @references_to_keys_map.delete(ref.referenced_object_id) if keys_to_id.empty?
        end
        ref.object
      else
        nil
      end
    end

    # Get the list of all values that have not yet been garbage collected.
    def values
      vals = []
      each{|k,v| vals << v}
      vals
    end

    # Turn the map into an arry of [key, value] entries
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
      @references.each do |key, ref|
        value = ref.object
        yield(key, value) if value
      end
    end

    # Clear the map of all key/value pairs.
    def clear
      @lock.synchronize do
        @references.clear
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
      @references.count do |_, ref|
        ref.object
      end
    end

    alias_method :length, :size

    # True if there are entries that exist in the map
    def empty?
      @references.each do |_, ref|
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

    def remove_reference_to(object_id)
      @lock.synchronize do
        keys = @references_to_keys_map[object_id]
        if keys
          keys.each do |key|
            @references.delete(key)
          end
          @references_to_keys_map.delete(object_id)
        end
      end
    end
  end
end
