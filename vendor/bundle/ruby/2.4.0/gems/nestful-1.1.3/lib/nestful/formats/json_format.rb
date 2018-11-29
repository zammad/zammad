begin
  require 'json'
rescue LoadError
  require 'json/pure'
end

module Nestful
  module Formats
    class JSONFormat < Format
      def mime_type
        'application/json'
      end

      def encode(hash, options = nil)
        hash.to_json(options)
      end

      def decode(json)
        JSON.parse(json)
      end
    end

    JsonFormat = JSONFormat
  end
end
