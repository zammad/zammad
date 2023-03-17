# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User
  class PermissionType < Gql::Types::BaseObject
    description 'Permissions for the current user'

    # Only allow usage of permission type for the current user itself.
    def self.authorize(object, ctx)
      ctx.current_user.id == object.id
    end

    field :names, [String], null: false, resolver_method: :resolve_names
    field :ids, [Integer], null: false, resolver_method: :resolve_ids

    def resolve_names
      @object.permissions_with_child_names
    end

    def resolve_ids
      @object.permissions_with_child_ids
    end
  end
end
