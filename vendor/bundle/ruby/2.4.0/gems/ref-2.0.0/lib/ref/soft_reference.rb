module Ref
  # A SoftReference represents a reference to an object that is not seen by
  # the tracing phase of the garbage collector. This allows the referenced
  # object to be garbage collected as if nothing is referring to it.
  #
  # A SoftReference differs from a WeakReference in that the garbage collector
  # is not so eager to reclaim soft references so they should persist longer.
  #
  # === Example usage:
  #
  #   foo = Object.new
  #   ref = Ref::SoftReference.new(foo)
  #   ref.object			# should be foo
  #   ObjectSpace.garbage_collect
  #   ref.object			# should be foo
  #   ObjectSpace.garbage_collect
  #   ObjectSpace.garbage_collect
  #   ref.object			# should be nil
  class SoftReference < Reference
    @@strong_references = [{}]
    @@gc_flag_set = false

    # Number of garbage collection cycles after an object is used before a reference to it can be reclaimed.
    MIN_GC_CYCLES = 10

    @@lock = Monitor.new

    @@finalizer = lambda do |object_id|
      @@lock.synchronize do
        while @@strong_references.size >= MIN_GC_CYCLES do
          @@strong_references.shift
        end
        @@strong_references.push({}) if @@strong_references.size < MIN_GC_CYCLES
        @@gc_flag_set = false
      end
    end

    # Create a new soft reference to an object.
    def initialize(obj)
      @referenced_object_id = obj.__id__
      @weak_reference = WeakReference.new(obj)
      add_strong_reference(obj)
    end

    # Get the referenced object. If the object has been reclaimed by the
    # garbage collector, then this will return nil.
    def object
      obj = @weak_reference.object
      # add a temporary strong reference each time the object is referenced.
      add_strong_reference(obj) if obj
      obj
    end

    private
      # Create a strong reference to the object. This reference will live
      # for three passes of the garbage collector.
      def add_strong_reference(obj) #:nodoc:
        @@lock.synchronize do
          @@strong_references.last[obj] = true
          unless @@gc_flag_set
            @@gc_flag_set = true
            ObjectSpace.define_finalizer(Object.new, @@finalizer)
          end
        end
      end
  end
end
