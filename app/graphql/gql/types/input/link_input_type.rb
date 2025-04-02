# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class LinkInputType < Gql::Types::BaseInputObject
    description 'Link input'

    argument :source_id, GraphQL::Types::ID, required: true, description: 'Source object ID'
    argument :target_id, GraphQL::Types::ID, required: true, description: 'Target object ID'
    argument :type, Gql::Types::Enum::LinkTypeType, required: true, description: 'Link type'
  end
end
