module Import
  class Exchange
    class ItemAttributes

      def self.extract(resource)
        new(resource).extract
      end

      def initialize(resource)
        @resource = resource
      end

      def extract
        @attributes ||= begin
          properties  = @resource.get_all_properties!
          result      = normalize(properties)
          flattened   = flatten(result)
          booleanized = booleanize_values(flattened)
        end
      end

      private

      def booleanize_values(properties)
        properties.each do |key, value|
          if value.is_a?(String)
            next if !%w(true false).include?(value)
            properties[key] = value == 'true'
          elsif value.is_a?(Hash)
            properties[key] = booleanize_values(value)
          end
        end
      end

      def normalize(properties)
        result = {}
        properties.each do |key, value|

          next if key == :body

          if value[:text]
            result[key] = value[:text]
          elsif value[:attribs]
            result[key] = value[:attribs]
          elsif value[:elems]
            result[key] = sub_elems(value[:elems])
          end
        end

        result
      end

      def sub_elems(elems)
        result = {}
        elems.each do |elem|
          if elem[:entry]
            result.merge!( sub_elem_entry( elem[:entry] ) )
          else
            result.merge!( normalize(elem) )
          end
        end
        result
      end

      def sub_elem_entry(entry)
        entry_value = {}
        if entry[:elems]
          entry_value = sub_elems(entry[:elems])
        end

        if entry[:text]
          entry_value[:text] = entry[:text]
        end

        if entry[:attribs].present?
          entry_value.merge!(entry[:attribs])
        end

        entry_key = entry_value.delete(:key)
        {
          entry_key => entry_value
        }
      end

      def flatten(properties, prefix: nil)

        result = {}
        properties.each do |key, value|

          result_key = key
          if prefix
            result_key = if %i(text id).include?(key) && ( !result[result_key] || result[result_key] == value )
                           prefix
                         else
                           "#{prefix}.#{key}".to_sym
                         end
          end
          result_key = result_key.to_s.downcase

          if value.is_a?(Hash)
            sub_result = flatten(value, prefix: result_key)
            result.merge!(sub_result)
          else
            result[result_key] = value.to_s
          end
        end
        result
      end
    end
  end
end
