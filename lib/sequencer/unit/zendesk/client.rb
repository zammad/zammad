# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Zendesk::Client < Sequencer::Unit::Common::Provider::Fallback

  provides :client

  private

  def client
    require 'zendesk_api' # Only load this gem when it is really used.
    ZendeskAPI::Client.new do |config|
      config.url = Setting.get('import_zendesk_endpoint')

      # Basic / Token Authentication
      config.username = Setting.get('import_zendesk_endpoint_username')
      config.token    = Setting.get('import_zendesk_endpoint_key')

      # when hitting the rate limit, sleep automatically,
      # then retry the request.
      config.retry = true

      # Activate the retry also for exception, e.g. for Faraday::SSLError.
      config.retry_on_exception = true

      # disable cache to avoid unneeded memory consumption
      # since we are using each object only once
      # Inspired by: https://medium.com/swiftype-engineering/using-jmat-to-find-analyze-memory-in-jruby-1c4196c1ec72
      config.cache = false

      # increase timeouts to avoid network issues.
      config.client_options = {
        request: {
          open_timeout: 20, # default is 10
          timeout:      120, # default is 60
        },
      }
    end
  end
end
