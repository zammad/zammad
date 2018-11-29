require 'faraday'

module Koala
  module HTTPService
    class MultipartRequest < Faraday::Request::Multipart
      # Facebook expects nested parameters to be passed in a certain way
      # Based on our testing (https://github.com/arsduo/koala/issues/125),
      # Faraday needs two changes to make that work:
      # 1) [] need to be escaped (e.g. params[foo]=bar ==> params%5Bfoo%5D=bar)
      # 2) such messages need to be multipart-encoded

      self.mime_type = 'multipart/form-data'.freeze

      def process_request?(env)
        # if the request values contain any hashes or arrays, multipart it
        super || !!(env[:body].respond_to?(:values) && env[:body].values.find {|v| v.is_a?(Hash) || v.is_a?(Array)})
      end


      def process_params(params, prefix = nil, pieces = nil, &block)
        params.inject(pieces || []) do |all, (key, value)|
          key = "#{prefix}%5B#{key}%5D" if prefix

          case value
          when Array
            values = value.inject([]) { |a,v| a << [nil, v] }
            process_params(values, key, all, &block)
          when Hash
            process_params(value, key, all, &block)
          else
            all << block.call(key, value)
          end
        end
      end
    end
  end
end