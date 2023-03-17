# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class OnlineNotificationType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields # Instead of IsModelObject to have custom #created_by and #updated_by
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Online notifications for a user'

    field :seen, Boolean, null: false

    lookup_field :type_name,   String, foreign_key: :type_lookup_id, null: false
    lookup_field :object_name, String, foreign_key: :object_lookup_id, null: false

    scoped_fields do
      belongs_to :created_by, Gql::Types::UserType, description: 'User that created this record', null: true
      belongs_to :updated_by, Gql::Types::UserType, description: 'Last user that updated this record', null: true

      belongs_to :meta_object, ActivityMessageMetaObjectType,
                 foreign_key: :o_id, through_key: :object_lookup_id,
                 null: true
    end
  end
end
