module Ref
  # A WeakReference represents a reference to an object that is not seen by
  # the tracing phase of the garbage collector. This allows the referenced
  # object to be garbage collected as if nothing is referring to it.
  #
  # === Example usage:
  #
  #   foo = Object.new
  #   ref = Ref::WeakReference.new(foo)
  #   ref.object			# should be foo
  #   ObjectSpace.garbage_collect
  #   ref.object			# should be nil
  class WeakReference < Reference
    
    # Create a weak reference to an object.
    def initialize(obj)
      raise NotImplementedError.new("This is an abstract class; you must require an implementation")
    end

    # Get the referenced object. If the object has been reclaimed by the
    # garbage collector, then this will return nil.
    def object
      raise NotImplementedError.new("This is an abstract class; you must require an implementation")
    end
  end
end
