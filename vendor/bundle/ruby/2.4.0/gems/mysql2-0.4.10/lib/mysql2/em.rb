# encoding: utf-8

require 'eventmachine'
require 'mysql2'

module Mysql2
  module EM
    class Client < ::Mysql2::Client
      module Watcher
        def initialize(client, deferable)
          @client = client
          @deferable = deferable
          @is_watching = true
        end

        def notify_readable
          detach
          begin
            result = @client.async_result
          rescue => e
            @deferable.fail(e)
          else
            @deferable.succeed(result)
          end
        end

        def watching?
          @is_watching
        end

        def unbind
          @is_watching = false
        end
      end

      def close(*args)
        @watch.detach if @watch && @watch.watching?

        super(*args)
      end

      def query(sql, opts = {})
        if ::EM.reactor_running?
          super(sql, opts.merge(:async => true))
          deferable = ::EM::DefaultDeferrable.new
          @watch = ::EM.watch(socket, Watcher, self, deferable)
          @watch.notify_readable = true
          deferable
        else
          super(sql, opts)
        end
      end
    end
  end
end
