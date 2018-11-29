module Ref
  # Implementation of a map in which only weakly referenced keys are kept to the map values.
  # This allows the garbage collector to reclaim these objects if the only reference to them
  # is the weak reference in the map.
  #
  # This is often useful for cache implementations since the map can be allowed to grow
  # without bound and the garbage collector can be relied on to clean it up as necessary.
  # One must be careful, though, when accessing entries since they can be collected at
  # any time until there is a strong reference to the key.
  #
  # === Example usage:
  #
  #   cache = Ref::WeakKeyMap.new
  #   obj = MyObject.find_by_whatever
  #   obj_info = Service.lookup_object_info(obj)
  #   cache[obj] = Service.lookup_object_info(obj)
  #   cache[obj]  # The values looked up from the service
  #   obj = nil
  #   ObjectSpace.garbage_collect
  #   cache.keys  # empty array since the keys and values have been reclaimed
  #
  # See AbstractReferenceKeyMap for details.
  class WeakKeyMap < AbstractReferenceKeyMap
    self.reference_class = WeakReference
  end
end
