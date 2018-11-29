module V8
  module Weak
    # weak refs are broken on MRI 1.9 and merely slow on 1.8
    # so we mitigate this by using the 'ref' gem. However, this
    # only mitigates the problem. Under heavy load, you will still
    # get different or terminated objects being returned. bad stuff.
    #
    # If you are having problems with this, an upgrade to 2.0 is *highly*
    # recommended.
    #
    # for other platforms we just use the stdlib 'weakref'
    # implementation
    if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'ruby' && RUBY_VERSION < '2.0.0'
      require 'ref'
      Ref = ::Ref::WeakReference
      WeakValueMap = ::Ref::WeakValueMap
    else
      require 'weakref'
      class Ref
        def initialize(object)
          @ref = ::WeakRef.new(object)
        end
        def object
          @ref.__getobj__
        rescue ::WeakRef::RefError
          nil
        end
      end

      class WeakValueMap
        def initialize
          @values = {}
        end

        def [](key)
          if ref = @values[key]
            ref.object
          end
        end

        def []=(key, value)
          ref = V8::Weak::Ref.new(value)
          ObjectSpace.define_finalizer(value, self.class.ensure_cleanup(@values, key, ref))

          @values[key] = ref
        end

        def self.ensure_cleanup(values,key,ref)
          proc {
            values.delete(key) if values[key] == ref
          }
        end
      end
    end

    module Cell
      def weakcell(name, &block)
        unless storage = instance_variable_get("@#{name}")
          storage = instance_variable_set("@#{name}", Storage.new)
        end
        storage.access(&block)
      end
      class Storage
        def access(&block)
          if @ref
            @ref.object || populate(block)
          else
            populate(block)
          end
        end

        private

        def populate(block)
          occupant = block.call()
          @ref = V8::Weak::Ref.new(occupant)
          return occupant
        end
      end
    end
  end
end