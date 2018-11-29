class V8::Conversion
  module Symbol
    def to_v8
      V8::C::String::NewSymbol(to_s)
    end
  end
end