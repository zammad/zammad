class V8::Conversion
  module Array
    def to_v8
      array = V8::Array.new(length)
      each_with_index do |item, i|
        array[i] = item
      end
      return array.to_v8
    end
  end
end