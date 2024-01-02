# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ExternalDataSource
  class HttpOptions
    def initialize(options)
      @options = options
    end

    def build
      output = { json: true, log: { facility: 'ExternalDataSource' } }

      add_basic_auth(output)
      add_bearer_token_auth(output)
      add_verify_ssl(output)

      output
    end

    def add_verify_ssl(output)
      return if @options[:verify_ssl].nil?

      output[:verify_ssl] = @options[:verify_ssl]
    end

    def add_basic_auth(output)
      return if @options[:http_basic_auth_username].blank? && @options[:http_basic_auth_password].blank?

      output[:user]     = @options[:http_basic_auth_username]
      output[:password] = @options[:http_basic_auth_password]
    end

    def add_bearer_token_auth(output)
      return if @options[:bearer_token_auth].blank?

      output[:bearer_token] = @options[:bearer_token_auth]
    end
  end
end
