module Nestful
  module Formats
    class FormFormat < Format
      def mime_type
        'application/x-www-form-urlencoded'
      end

      def encode(params, options = nil)
        Helpers.to_param(params)
      end

      def decode(body)
        body
      end
    end
  end
end