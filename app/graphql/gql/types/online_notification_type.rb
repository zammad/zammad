# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class OnlineNotificationType < Gql::Types::BaseObject
    include Gql::Concerns::IsModelObject
    include Gql::Concerns::HasPunditAuthorization

    description 'Online notifications for a user'

    field :seen,      Boolean, null: false
    field :object_id, Integer, method: :o_id, null: false

    lookup_field :type_name,   String, method: :type_lookup_id, null: false
    lookup_field :object_name, String, method: :object_lookup_id, null: false

    belongs_to :metaObject, ActivityMessageMetaObjectType,
               foreign_key: :o_id, through_key: :object_lookup_id, null: false
  end
end
