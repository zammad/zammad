require 'ref'

class V8::Conversion
  module Identity
    def to_ruby(v8_object)
      if v8_object.class <= V8::C::Object
        v8_idmap[v8_object.GetIdentityHash()] || super(v8_object)
      else
        super(v8_object)
      end
    end

    def to_v8(ruby_object)
      return super(ruby_object) if ruby_object.is_a?(String) || ruby_object.is_a?(Primitive)
      rb_idmap[ruby_object.object_id] || super(ruby_object)
    end

    def equate(ruby_object, v8_object)
      v8_idmap[v8_object.GetIdentityHash()] = ruby_object
      rb_idmap[ruby_object.object_id] = v8_object
    end

    def v8_idmap
      @v8_idmap ||= V8::Weak::WeakValueMap.new
    end

    def rb_idmap
      @ruby_idmap ||= V8::Weak::WeakValueMap.new
    end
  end
end