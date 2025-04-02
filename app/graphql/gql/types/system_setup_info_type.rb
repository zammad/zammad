# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class SystemSetupInfoType < Gql::Types::BaseObject

    description 'System setup state.'

    field :status, Gql::Types::Enum::SystemSetupInfoStatusType, null: false, description: 'System setup status.'
    field :type, Gql::Types::Enum::SystemSetupInfoTypeType, null: true, description: 'System setup type.'
  end
end
