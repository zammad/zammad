# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class AuthenticationProviderType < BaseEnum
    description 'Available thirdparty authentication providers'

    build_string_list_enum(Authorization::Provider.descendants.map { |klass| klass.name.demodulize.underscore }.sort)

    value 'sso' # No class exists for SSO, add it manually.
  end
end
