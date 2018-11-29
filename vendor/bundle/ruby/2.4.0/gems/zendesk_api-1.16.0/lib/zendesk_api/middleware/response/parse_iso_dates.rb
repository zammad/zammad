require 'time'
require "faraday/response"

module ZendeskAPI
  module Middleware
    module Response
      # Parse ISO dates from response body
      # @private
      class ParseIsoDates < Faraday::Response::Middleware
        def call(env)
          @app.call(env).on_complete do |env|
            parse_dates!(env[:body])
          end
        end

        private

        def parse_dates!(value)
          case value
          when Hash then value.each { |key, element| value[key] = parse_dates!(element) }
          when Array then value.each_with_index { |element, index| value[index] = parse_dates!(element) }
          when /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\Z/m then Time.parse(value)
          else
            value
          end
        end
      end
    end
  end
end
