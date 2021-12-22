# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Queries
  class ApplicationConfig < BaseQuery

    description 'Configuration required for front end operation (more results returned for authenticated users)'

    type [Gql::Types::KeyComplexValueType, { null: false }], null: false

    # Reimplemented from sessions_controller#config_frontend.
    def resolve(...)
      result = []
      unauthenticated = context.current_user?.nil?
      Setting.select('name, preferences').where(frontend: true).each do |setting|
        next if setting.preferences[:authentication] && unauthenticated

        value = Setting.get(setting.name)
        next if unauthenticated && !value

        result << { key: setting.name, value: value }
      end
      result
    end

  end
end
