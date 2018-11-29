module Ref
  # This is a pure ruby implementation of a weak reference. It is much more
  # efficient than the WeakRef implementation bundled in MRI 1.8 and 1.9
  # subclass Delegator which is very heavy to instantiate and utilizes a
  # because it does not fair amount of memory under Ruby 1.8.
  class WeakReference < Reference

    class ReferencePointer
      def initialize(object)
        @referenced_object_id = object.__id__
        add_backreference(object)
      end

      def cleanup
        obj = ObjectSpace._id2ref(@referenced_object_id) rescue nil
        remove_backreference(obj) if obj
      end

      def object
        obj = ObjectSpace._id2ref(@referenced_object_id)
        obj if verify_backreferences(obj)
      rescue RangeError
        nil
      end

      private
        # Verify that the object is the same one originally set for the weak reference.
        def verify_backreferences(obj) #:nodoc:
          return nil unless supports_backreference?(obj)
          backreferences = obj.instance_variable_get(:@__weak_backreferences__) if obj.instance_variable_defined?(:@__weak_backreferences__)
          backreferences && backreferences.include?(object_id)
        end

        # Add a backreference to the object.
        def add_backreference(obj) #:nodoc:
          return unless supports_backreference?(obj)
          backreferences = obj.instance_variable_get(:@__weak_backreferences__) if obj.instance_variable_defined?(:@__weak_backreferences__)
          unless backreferences
            backreferences = []
            obj.instance_variable_set(:@__weak_backreferences__, backreferences)
          end
          backreferences << object_id
        end

        # Remove backreferences from the object.
        def remove_backreference(obj) #:nodoc:
          return unless supports_backreference?(obj)
          backreferences = obj.instance_variable_get(:@__weak_backreferences__) if obj.instance_variable_defined?(:@__weak_backreferences__)
          if backreferences
            backreferences.dup.delete(object_id)
            obj.send(:remove_instance_variable, :@__weak_backreferences__) if backreferences.empty?
          end
        end

        def supports_backreference?(obj)
          obj.respond_to?(:instance_variable_get) && obj.respond_to?(:instance_variable_defined?)
        rescue NoMethodError
          false
        end
    end

    @@weak_references = {}
    @@lock = Monitor.new

    # Finalizer that cleans up weak references when references are destroyed.
    @@reference_finalizer = lambda do |object_id|
      @@lock.synchronize do
        reference_pointer = @@weak_references.delete(object_id)
        reference_pointer.cleanup if reference_pointer
      end
    end

    # Create a new weak reference to an object. The existence of the weak reference
    # will not prevent the garbage collector from reclaiming the referenced object.
    def initialize(obj) #:nodoc:
      @referenced_object_id = obj.__id__
      @@lock.synchronize do
        @reference_pointer = ReferencePointer.new(obj)
        @@weak_references[self.object_id] = @reference_pointer
      end
      ObjectSpace.define_finalizer(self, @@reference_finalizer)
    end

    # Get the reference object. If the object has already been garbage collected,
    # then this method will return nil.
    def object #:nodoc:
      if @reference_pointer
        obj = @reference_pointer.object
        unless obj
          @@lock.synchronize do
            @@weak_references.delete(object_id)
            @reference_pointer.cleanup
            @reference_pointer = nil
          end
        end
        obj
      end
    end
  end
end
