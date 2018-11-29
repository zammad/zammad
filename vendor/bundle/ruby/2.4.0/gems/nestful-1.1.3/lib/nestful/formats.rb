module Nestful
  module Formats
    class Format
      def mime_type
      end

      def encode(*args)
      end

      def decode(*args)
      end
    end

    MAPPING = {
      'application/json' => :json
    }

    def self.for(type)
      format = MAPPING[type]
      format && self[format]
    end

    # Lookup the format class from a mime type reference symbol. Example:
    #
    #   Nestful::Formats[:json] # => Nestful::Formats::JsonFormat
    def self.[](mime_type_reference)
      Nestful::Formats.const_get(Helpers.camelize(mime_type_reference.to_s) + 'Format')
    end
  end
end

Dir[File.dirname(__FILE__) + '/formats/*.rb'].sort.each do |path|
  filename = File.basename(path)
  require "nestful/formats/#{filename}"
end