require "uri"

class Nori
  module CoreExt
    module Hash

      # @param key<Object> The key for the param.
      # @param value<Object> The value for the param.
      #
      # @return <String> This key value pair as a param
      #
      # @example normalize_param(:name, "Bob Jones") #=> "name=Bob%20Jones"
      def normalize_param(key, value)
        if value.is_a?(Array)
          normalize_array_params(key, value)
        elsif value.is_a?(Hash)
          normalize_hash_params(key, value)
        else
          normalize_simple_type_params(key, value)
        end
      end

      # @return <String> The hash as attributes for an XML tag.
      #
      # @example
      #   { :one => 1, "two"=>"TWO" }.to_xml_attributes
      #     #=> 'one="1" two="TWO"'
      def to_xml_attributes
        map do |k, v|
          %{#{k.to_s.snakecase.sub(/^(.{1,1})/) { |m| m.downcase }}="#{v}"}
        end.join(' ')
      end

      private

      def normalize_simple_type_params(key, value)
        ["#{key}=#{encode_simple_value(value)}"]
      end

      def normalize_array_params(key, array)
        array.map do |element|
          normalize_param("#{key}[]", element)
        end
      end

      def normalize_hash_params(key, hash)
        hash.map do |nested_key, element|
          normalize_param("#{key}[#{nested_key}]", element)
        end
      end

      def encode_simple_value(value)
        URI.encode(value.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      end

    end
  end
end

Hash.send :include, Nori::CoreExt::Hash
