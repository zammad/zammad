class V8::Conversion
  module Time
    def to_v8
      V8::C::Date::New(to_f * 1000)
    end
  end

  module NativeDate
    def to_ruby
      ::Time.at(self.NumberValue() / 1000)
    end
  end
end