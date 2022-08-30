# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class UserLocatorInputType < Gql::Types::BaseInputObject

    description 'Locate an user via id or internalId.'

    argument :user_id, GraphQL::Types::ID, required: false, description: 'User ID'
    argument :user_internal_id, Integer, required: false, description: 'User internalId'

    validates required: { one_of: %i[user_id user_internal_id] }

    def prepare
      super
      find_user.tap do |user|
        Pundit.authorize(context.current_user, user, :show?)
      rescue Pundit::NotAuthorizedError => e
        raise Exceptions::Forbidden, e.message
      end
    end

    def find_user
      if user_internal_id
        return ::User.find_by(id: user_internal_id) || raise(ActiveRecord::RecordNotFound, "No user found for #{user_internal_id}.")
      end

      Gql::ZammadSchema.verified_object_from_id(user_id, type: ::User)
    end
  end
end
