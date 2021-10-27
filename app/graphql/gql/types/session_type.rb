# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Types
  class SessionType < Gql::Types::BaseObject
    # include Gql::Concern::IsModelObject

    # def self.authorize(object, ctx)
    #  Pundit.authorize ctx[:current_user], object, :show?
    # end

    description 'Data of a current session'

    field :session_id, String, null: false
    field :data, GraphQL::Types::JSON, null: true
  end
end
