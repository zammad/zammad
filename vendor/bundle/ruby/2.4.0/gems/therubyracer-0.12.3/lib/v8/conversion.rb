
class V8::Conversion
  include Fundamental
  include Identity

  def to_ruby(v8_object)
    super v8_object
  end

  def to_v8(ruby_object)
    super ruby_object
  end
end

for type in [TrueClass, FalseClass, NilClass, Float] do
  type.class_eval do
    include V8::Conversion::Primitive
  end
end

for type in [Class, Object, Array, Hash, String, Symbol, Time, Proc, Method, Integer] do
  type.class_eval do
    include V8::Conversion.const_get(type.name)
  end
end

class UnboundMethod
  include V8::Conversion::Method
end

for type in [:Object, :String, :Date] do
  V8::C::const_get(type).class_eval do
    include V8::Conversion::const_get("Native#{type}")
  end
end

