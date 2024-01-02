# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class ApplicationConfig < BaseQuery

    description 'Configuration required for front end operation (more results returned for authenticated users)'

    type [Gql::Types::KeyComplexValueType, { null: false }], null: false

    def self.authorize(...)
      true # This query should be available for all (including unauthenticated) users.
    end

    # Reimplemented from sessions_controller#config_frontend.
    def resolve(...)
      frontend_settings + rails_application_config + custom_settings
    end

    private

    def unauthenticated?
      context.current_user?.nil?
    end

    def frontend_settings
      Setting.select('name, preferences').where(frontend: true).each_with_object([]) do |setting, result|
        next if setting.preferences[:authentication] && unauthenticated?

        value = Setting.get(setting.name)
        next if unauthenticated? && !value

        result << { key: setting.name, value: value }
      end
    end

    def rails_application_config
      [
        'active_storage.web_image_content_types',
      ].map do |config_name|
        (method, key) = config_name.split('.')

        value = Rails.application.config.send(method)
        value = value[key.to_sym] if key.present?

        { key: config_name, value: value }
      end
    end

    def custom_settings
      [
        'auth_saml_credentials.display_name',
      ].filter_map do |config_name|
        (setting, key) = config_name.split('.')

        value = Setting.get(setting)
        value = value[key.to_sym] if key.present?
        next if unauthenticated? && !value

        { key: config_name, value: value }
      end
    end
  end
end
