module Ref
  # Implementation of a map in which weak references are kept to the map values.
  # This allows the garbage collector to reclaim these objects if the
  # only reference to them is the weak reference in the map.
  #
  # This is often useful for cache  implementations since the map can be allowed to grow
  # without bound and the  garbage collector can be relied on to clean it up as necessary.
  # One must be careful,  though, when accessing entries since the values can be collected
  # at any time until there is a strong reference to them.
  #
  # === Example usage:
  #
  #   cache = Ref::WeakValueMap.new
  #   foo = "foo"
  #   cache["strong"] = foo  # add a value with a strong reference
  #   cache["weak"] = "bar"  # add a value without a strong reference
  #   cache["strong"]        # "foo"
  #   cache["weak"]          # "bar"
  #   ObjectSpace.garbage_collect
  #   cache["strong"]        # "foo"
  #   cache["weak"]          # nil
  #
  # See AbstractReferenceValueMap for details.
  class WeakValueMap < AbstractReferenceValueMap
    self.reference_class = WeakReference
  end
end
