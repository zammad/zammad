class V8::Conversion
  module String
    def to_v8
      V8::C::String::New(self)
    end
  end
  module NativeString
    def to_ruby
      self.Utf8Value()
    end
  end
end