module Ref
  # This implementation of Reference holds a strong reference to an object. The
  # referenced object will not be garbage collected as long as the strong reference
  # exists.
  class StrongReference < Reference
    # Create a new strong reference to an object.
    def initialize(obj)
      @obj = obj
      @referenced_object_id = obj.__id__
    end
    
    # Get the referenced object.
    def object
      @obj
    end
  end
end
