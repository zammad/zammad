class V8::Conversion
  module Object
    def to_v8
      Reference.construct! self
    end

    def to_ruby
      self
    end
  end

  module NativeObject
    def to_ruby
      wrap = if IsArray()
        ::V8::Array
      elsif IsFunction()
        ::V8::Function
      else
        ::V8::Object
      end
      wrap.new(self)
    end

    def to_v8
      self
    end
  end
end