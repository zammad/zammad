# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class GroupType < Gql::Types::BaseObject
    include Gql::Concern::IsModelObject

    description 'Groups'

    # field :signature_id, Integer, null: true
    # field :email_address_id, Integer, null: true
    field :name, String, null: false
    field :assignment_timeout, Integer, null: true
    field :follow_up_possible, String, null: false
    field :follow_up_assignment, Boolean, null: false
    field :active, Boolean, null: false
    field :note, String, null: true
  end
end
