class V8::Conversion
  module Reference

    def self.construct!(object)
      context = V8::Context.current
      constructor = context.to_v8(object.class)
      reference = constructor.NewInstance([V8::C::External::New(object)])
      return reference
    end

    def to_v8
      Reference.construct! self
    end

  end
end