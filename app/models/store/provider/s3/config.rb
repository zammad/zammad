# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Store::Provider::S3::Config
  class << self

    PATH = Rails.root.join('config/zammad/storage.yml')
    VARIABLE = 'S3_URL'.freeze
    NAME = 's3'.freeze

    def bucket
      settings[:bucket]
    end

    def max_chunk_size
      settings[:max_chunk_size].presence || 100.megabytes
    end

    def apply
      return true if Aws.config.present?

      begin
        config = settings.deep_dup
        credentials = Aws::Credentials.new(config[:access_key_id], config[:secret_access_key])
        config[:credentials] = credentials

        %i[access_key_id secret_access_key bucket max_chunk_size].each do |key|
          config.delete(key)
        end

        Aws.config.update(config)
      rescue => e
        Rails.logger.error { "#{name}: #{e.message}" }
        raise Store::Provider::S3::Error, __('Simple Storage Service configuration not found or invalid.')
      end

      true
    end

    def reset
      @config = nil
      Aws.config = {}

      true
    end

    private

    def settings
      return @config if @config.present?

      config = Zammad::Service::Configuration.parse(yaml: PATH, env: VARIABLE, adapter: NAME)

      @config = config.presence || (raise Store::Provider::S3::Error, __('Simple Storage Service configuration not found or invalid.'))
    end
  end
end
