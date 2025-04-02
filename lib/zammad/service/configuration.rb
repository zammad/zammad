# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Zammad
  module Service
    ##
    # This module provides a method to parse a Zammad third-party service
    # configuration from a YAML file and/or environment variable.
    #
    # The YAML file provides the settings in a key-value format. The
    # environment variable provides the settings in a URL-like format.
    #
    # If both sources are present, the provided settings are merged together.
    # The environment variable takes precedence.
    #
    # Setting the +url+ key-value in the YAML file will prevent the environment
    # variable from being parsed.
    module Configuration
      class << self

        ##
        # Parses the configuration from the YAML file and/or environment
        # variable.
        #
        # The parameter +yaml+ takes the path to the file as pathname object.
        # The parameter +env+ takes the name of the environment variable.
        # The parameter +adapter+ takes the name of the service adapter.
        # The parameter +rails_env+ takes a boolean value whether to consider
        # the Rails environment.
        # The last two parameters determine the entrypoint of the YAML file.
        #
        # The method returns a hash with the parsed configuration.
        #
        #     Zammad::Service::Configuration.parse(
        #       yaml: Rails.root.join('config/'zammad/s3.yml'),
        #       env: 'S3_URL',
        #       adapter: 's3',
        #       rails_env: false
        #     )
        #
        def parse(yaml: nil, env: nil, adapter: nil, rails_env: false)
          @yaml = yaml
          @env = env
          @adapter = adapter
          @rails_env = rails_env

          config = {}
          %i[yaml env].each do |key|
            begin
              next if key == :env && config[:url].present?

              config.deep_merge!(send(key))
            rescue => e
              Rails.logger.error { "#{name}: #{e.message}" }
              next
            end
          end
          config.delete(:url)

          config
        end

        private

        def yaml
          return {} if @yaml.blank? || !@yaml.exist?

          config = YAML.load_file(@yaml, aliases: true).deep_symbolize_keys
          config = config[Rails.env.to_sym] if @rails_env
          config = config[@adapter.to_sym] if @adapter.present?

          return config if config[:url].blank?

          config.deep_merge(resolve_url(config[:url]))
        end

        def env
          return {} if ENV[@env].blank?

          resolve_url(ENV[@env])
        end

        def resolve_url(url)
          uri = URI.parse(url)

          config = template(uri)
          query = uri.opaque.present? ? uri.opaque.split('?', 2) : uri.query

          config.compact!
          return config if query.blank?

          query.split('&').each do |option|
            key, value = option.split('=', 2)
            value = URI::DEFAULT_PARSER.unescape(value)
            value = boolean(value)
            value = number(value)

            config[key.to_sym] = value
          end

          config.compact!
          config
        end

        def boolean(value)
          return true if value == 'true'
          return false if value == 'false'

          value
        end

        def number(value)
          number = Float(value)
          return number if value.include?('.')

          number.to_i
        rescue
          value
        end

        def template(uri)
          case @adapter
          when 's3'
            {
              bucket:            uri.path.present? ? uri.path.sub(%r{^/}, '') : nil,
              endpoint:          "#{uri.scheme}://#{uri.host}" + (uri.port.present? ? ":#{uri.port}" : ''),
              access_key_id:     uri.user.presence,
              secret_access_key: uri.password.presence,
            }
          else
            {}
          end
        end

      end
    end
  end
end
