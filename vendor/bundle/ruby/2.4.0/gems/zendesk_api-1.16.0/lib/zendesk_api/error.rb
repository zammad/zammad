# tested via spec/core/middleware/response/raise_error_spec.rb
module ZendeskAPI
  module Error
    class ClientError < Faraday::Error::ClientError
      attr_reader :wrapped_exception

      def to_s
        if response
          "#{super} -- #{response.method} #{response.url}"
        else
          super
        end
      end
    end

    class RecordInvalid < ClientError
      attr_accessor :errors

      def initialize(*)
        super

        if response[:body].is_a?(Hash)
          @errors = response[:body]["details"] || response[:body]["description"]
        end

        @errors ||= {}
      end

      def to_s
        "#{self.class.name}: #{@errors}"
      end
    end

    class NetworkError < ClientError; end
    class RecordNotFound < ClientError; end
  end
end
