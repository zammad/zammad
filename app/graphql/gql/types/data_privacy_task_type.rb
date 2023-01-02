# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class DataPrivacyTaskType < BaseObject
    include Gql::Concerns::IsModelObject
    include Gql::Concerns::HasPunditAuthorization

    description 'Data privacy task type'

    field :state, String, null: true
    field :deletable_type, String, null: true
    field :deletable_id, Integer, null: true
  end
end
