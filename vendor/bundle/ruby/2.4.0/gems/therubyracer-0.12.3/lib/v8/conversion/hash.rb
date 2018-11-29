class V8::Conversion
  module Hash
    def to_v8
      object = V8::Object.new
      each do |key, value|
        object[key] = value
      end
      return object.to_v8
    end
  end
end