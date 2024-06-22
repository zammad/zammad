# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::NotificationPreferencesUpdate < BaseMutation
    description 'Update user notification settings'

    argument :group_ids, [GraphQL::Types::ID, { null: false }], required: false, description: 'Limit notifications to specified groups, if any'
    argument :matrix, Gql::Types::Input::User::NotificationMatrixInputType, description: 'Ticket notification preference matrix'
    argument :sound, Gql::Types::Input::User::NotificationSoundInputType, description: 'Ticket notification sound preference'

    field :user, Gql::Types::UserType, null: false, description: 'Updated user object'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.notifications+ticket.agent')
    end

    def resolve(matrix:, sound:, group_ids: nil)
      user = context.current_user

      user.with_lock do
        user.preferences.merge! new_config(group_ids:, matrix:, sound:)
        user.save!
      end

      { user: user.reload }
    end

    def new_config(matrix:, sound:, group_ids: nil)
      config = { matrix: matrix.to_h }
      config[:group_ids] = group_internal_ids(group_ids) if group_ids.present?

      {
        notification_config: config,
        notification_sound:  sound.to_h,
      }
    end

    def group_internal_ids(group_ids)
      group_ids.map do |gid|
        Gql::ZammadSchema.authorized_object_from_id(gid, type: Group, user: context.current_user).id
      end
    end
  end
end
