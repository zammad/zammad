module Import
  module Zendesk
    module Requester

      # rubocop:disable Style/ModuleFunction
      extend self

      def connection_test
        # make sure to reinitialize client
        # to react to config changes
        initialize_client
        return true if client.users.first
        false
      end

      def client
        return @client if @client
        initialize_client
        @client
      end

      private

      def initialize_client
        @client = ZendeskAPI::Client.new do |config|
          config.url = Setting.get('import_zendesk_endpoint')

          # Basic / Token Authentication
          config.username = Setting.get('import_zendesk_endpoint_username')
          config.token    = Setting.get('import_zendesk_endpoint_key')

          # when hitting the rate limit, sleep automatically,
          # then retry the request.
          config.retry = true

          # disable cache to avoid unneeded memory consumption
          # since we are using each object only once
          # Inspired by: https://medium.com/swiftype-engineering/using-jmat-to-find-analyze-memory-in-jruby-1c4196c1ec72
          config.cache = false
        end
      end
    end
  end
end
