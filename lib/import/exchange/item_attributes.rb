# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
        @extract ||= begin
          properties  = @resource.get_all_properties!
          result      = normalize(properties)
          flattened   = flatten(result)
          booleanize_values(flattened)
        end
      end

      private

      def booleanize_values(properties)
        booleans = %w[true false]
        properties.each do |key, value|
          case value
          when String
            next if booleans.exclude?(value)

            properties[key] = value == 'true'
          when Hash
            properties[key] = booleanize_values(value)
          end
        end
      end

      def normalize(properties)
        properties.each_with_object({}) do |(key, value), result|

          next if key == :body

          if value[:text]
            result[key] = value[:text]
          elsif value[:attribs]
            result[key] = value[:attribs]
          elsif value[:elems]
            result[key] = sub_elems(value[:elems])
          end
        end
      end

      def sub_elems(elems)
        elems.each_with_object({}) do |elem, result|
          if elem[:entry]
            result.merge!( sub_elem_entry( elem[:entry] ) )
          else
            result.merge!( normalize(elem) )
          end
        end
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
        keys = %i[text id]
        properties.each_with_object({}) do |(key, value), result|

          result_key = key
          if prefix
            result_key = if keys.include?(key) && ( !result[result_key] || result[result_key] == value )
                           prefix
                         else
                           :"#{prefix}.#{key}"
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
      end
    end
  end
end
