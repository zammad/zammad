module ActiveRecord
  class AttributeSet # :nodoc:
    class Builder # :nodoc:
      silence_warnings do
        def build_from_database(values = {}, additional_types = {})
          # CPK
          # if always_initialized && !values.key?(always_initialized)
          #   values[always_initialized] = nil
          # end
          Array(always_initialized).each do |always_initialized_attribute|
            if always_initialized_attribute && !values.key?(always_initialized_attribute)
              values[always_initialized_attribute] = nil
            end
          end

          attributes = LazyAttributeHash.new(types, values, additional_types)
          AttributeSet.new(attributes)
        end
      end
    end
  end
end