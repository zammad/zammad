# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Concerns::IsModelObject # rubocop:disable GraphQL/ObjectDescription
  extend ActiveSupport::Concern

  include Gql::Types::Concerns::HasDefaultModelFields
  include Gql::Types::Concerns::HasDefaultModelUserRelations
end
