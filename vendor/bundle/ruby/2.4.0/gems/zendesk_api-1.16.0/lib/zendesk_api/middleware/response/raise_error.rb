require 'zendesk_api/error'

module ZendeskAPI
  module Middleware
    module Response
      class RaiseError < Faraday::Response::RaiseError
        def call(env)
          super
        rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed => e
          raise Error::NetworkError.new(e, env)
        end

        def on_complete(env)
          case env[:status]
          when 404
            raise Error::RecordNotFound.new(env)
          when 422, 413
            raise Error::RecordInvalid.new(env)
          when 100..199, 400..599, 300..303, 305..399
            raise Error::NetworkError.new(env)
          end
        end
      end
    end
  end
end
