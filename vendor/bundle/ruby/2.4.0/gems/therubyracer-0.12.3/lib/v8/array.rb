class V8::Array < V8::Object

  def initialize(native_or_length = nil)
    super do
      if native_or_length.is_a?(Numeric)
        V8::C::Array::New(native_or_length)
      elsif native_or_length.is_a?(V8::C::Array)
        native_or_length
      else
        V8::C::Array::New()
      end
    end
  end

  def each
    @context.enter do
      0.upto(@native.Length() - 1) do |i|
        yield @context.to_ruby(@native.Get(i))
      end
    end
  end

  def length
    @native.Length()
  end
end