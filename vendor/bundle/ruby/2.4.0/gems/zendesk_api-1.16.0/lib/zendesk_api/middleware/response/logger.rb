module ZendeskAPI
  module Middleware
    module Response
      # Faraday middleware to handle logging
      # @private
      class Logger < Faraday::Middleware
        LOG_LENGTH = 1000

        def initialize(app, logger = nil)
          super(app)

          @logger = logger || begin
            require 'logger'
            ::Logger.new(STDOUT)
          end
        end

        def call(env)
          @logger.info "#{env[:method]} #{env[:url].to_s}"
          @logger.debug dump_debug(env, :request_headers)

          @app.call(env).on_complete do |env|
            info = "Status #{env[:status]}"
            info.concat(" #{env[:body].to_s[0, LOG_LENGTH]}") if (400..499).cover?(env[:status].to_i)

            @logger.info info
            @logger.debug dump_debug(env, :response_headers)
          end
        end

        private

        def dump_debug(env, headers_key)
          info = env[headers_key].map { |k, v| "  #{k}: #{v.inspect}" }.join("\n")
          unless env[:body].nil?
            info.concat("\n")
            info.concat(env[:body].inspect)
          end
          info
        end
      end
    end
  end
end
