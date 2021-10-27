# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Types
  class OrganizationType < Gql::Types::BaseObject
    include Gql::Concern::IsModelObject

    def self.authorize(object, ctx)
      Pundit.authorize ctx[:current_user], object, :show?
    end

    description 'Organizations that users can belong to'

    field :name, String, null: false
    field :shared, Boolean, null: false
    field :domain, String, null: true
    field :domain_assignment, Boolean, null: false
    field :active, Boolean, null: false
    field :note, String, null: true
    field :members, Gql::Types::UserType.connection_type, null: false
  end
end
