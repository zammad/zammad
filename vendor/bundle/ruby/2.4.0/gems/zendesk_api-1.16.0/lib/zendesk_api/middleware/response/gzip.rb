require 'zlib'
require 'stringio'

module ZendeskAPI
  # @private
  module Middleware
    # @private
    module Response
      # Faraday middleware to handle content-encoding = gzip
      class Gzip < Faraday::Response::Middleware
        def on_complete(env)
          if !env[:body].strip.empty? && env[:response_headers]['content-encoding'] == "gzip"
            env[:body] = Zlib::GzipReader.new(StringIO.new(env[:body])).read
          end
        end
      end
    end
  end
end
