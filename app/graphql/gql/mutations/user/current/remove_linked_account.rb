# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::RemoveLinkedAccount < BaseMutation
    description "Remove a linked account of the current user's profile"

    argument :provider, Gql::Types::Enum::AuthenticationProviderType, description: 'Internal name of the provider'
    argument :uid,      String, description: 'UID of the linked account'

    field :success, Boolean, null: false, description: 'Was the linked account removed?'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.linked_accounts')
    end

    def resolve(provider:, uid:)

      Service::User::RemoveLinkedAccount.new(provider:, uid:, current_user: context.current_user).execute

      { success: true }
    end
  end
end
