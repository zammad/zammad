module Ref
  # This class serves as a generic reference mechanism to other objects. The
  # actual reference can be either a WeakReference, SoftReference, or StrongReference.
  class Reference
    # The object id of the object being referenced.
    attr_reader :referenced_object_id
    
    # Create a new reference to an object.
    def initialize(obj)
      raise NotImplementedError.new("cannot instantiate a generic reference")
    end
    
    # Get the referenced object. This could be nil if the reference
    # is a WeakReference or a SoftReference and the object has been reclaimed by the garbage collector.
    def object
      raise NotImplementedError
    end

    def inspect
      obj = object
      "<##{self.class.name}: #{obj ? obj.inspect : "##{referenced_object_id} (not accessible)"}>"
    end
  end
end
