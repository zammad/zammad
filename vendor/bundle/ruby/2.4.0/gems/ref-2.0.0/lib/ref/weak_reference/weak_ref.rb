require 'weakref'

module Ref
  class WeakReference < Reference
  # This implementation of a weak reference simply wraps the standard WeakRef implementation
  # that comes with the Ruby standard library.
    def initialize(obj) #:nodoc:
      @referenced_object_id = obj.__id__
      @ref = ::WeakRef.new(obj)
    end

    def object #:nodoc:
      @ref.__getobj__
    rescue => e
      # Jruby implementation uses RefError while MRI uses WeakRef::RefError
      if (defined?(RefError) && e.is_a?(RefError)) || (defined?(::WeakRef::RefError) && e.is_a?(::WeakRef::RefError))
        nil
      else
        raise e
      end
    end
  end
end
