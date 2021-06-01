# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

%w[
  .ruby-version
  .rbenv-vars
  tmp/restart.txt
  tmp/caching-dev.txt
].each { |path| Spring.watch(path) }

module Spring
  module Commands
    class SchedulerRb

      def call
        load ::Rails.root.join('script/scheduler.rb')
      end
    end

    Spring.register_command 'scheduler.rb', Spring::Commands::SchedulerRb.new
  end
end

module Spring
  module Commands
    class WebsocketServerRb

      def call
        load ::Rails.root.join('script/websocket-server.rb')
      end
    end

    Spring.register_command 'websocket-server.rb', Spring::Commands::WebsocketServerRb.new
  end
end

module Spring
  module Commands
    class RailsServer < Rails
      def command_name
        'server'
      end
    end

    Spring.register_command 'rails_server', RailsServer.new
  end
end
