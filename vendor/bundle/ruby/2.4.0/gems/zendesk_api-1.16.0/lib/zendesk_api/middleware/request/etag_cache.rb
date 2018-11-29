require "faraday/middleware"

module ZendeskAPI
  module Middleware
    module Request
      # Request middleware that caches responses based on etags
      # can be removed once this is merged: https://github.com/pengwynn/faraday_middleware/pull/42
      # @private
      class EtagCache < Faraday::Middleware
        def initialize(app, options = {})
          @app = app
          @cache = options[:cache] ||
            raise("need :cache option e.g. ActiveSupport::Cache::MemoryStore.new")
          @cache_key_prefix = options.fetch(:cache_key_prefix, :faraday_etags)
        end

        def cache_key(env)
          [@cache_key_prefix, env[:url].to_s]
        end

        def call(environment)
          return @app.call(environment) unless [:get, :head].include?(environment[:method])

          # send known etag
          cached = @cache.read(cache_key(environment))

          if cached
            environment[:request_headers]["If-None-Match"] ||= cached[:response_headers]["Etag"]
          end

          @app.call(environment).on_complete do |env|
            if cached && env[:status] == 304 # not modified
              env[:body] = cached[:body]
              env[:response_headers].merge!(
                :etag => cached[:response_headers][:etag],
                :content_type => cached[:response_headers][:content_type],
                :content_length => cached[:response_headers][:content_length],
                :content_encoding => cached[:response_headers][:content_encoding]
              )
            elsif env[:status] == 200 && env[:response_headers]["Etag"] # modified and cacheable
              @cache.write(cache_key(env), env.to_hash)
            end
          end
        end
      end
    end
  end
end
