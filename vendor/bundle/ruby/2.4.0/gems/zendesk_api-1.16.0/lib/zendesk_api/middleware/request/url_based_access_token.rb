module ZendeskAPI
  # @private
  module Middleware
    # @private
    module Request
      class UrlBasedAccessToken < Faraday::Middleware
        def initialize(app, token)
          super(app)
          @token = token
        end

        def call(env)
          if env[:url].query
            env[:url].query += '&'
          else
            env[:url].query = ''
          end

          env[:url].query += "access_token=#{@token}"

          @app.call(env)
        end
      end
    end
  end
end
