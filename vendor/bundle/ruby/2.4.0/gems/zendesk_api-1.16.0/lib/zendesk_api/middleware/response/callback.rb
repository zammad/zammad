require "faraday/response"

module ZendeskAPI
  module Middleware
    module Response
      # @private
      class Callback < Faraday::Response::Middleware
        def initialize(app, client)
          super(app)
          @client = client
        end

        def call(env)
          @app.call(env).on_complete do |env|
            @client.callbacks.each { |c| c.call(env) }
          end
        end
      end
    end
  end
end
