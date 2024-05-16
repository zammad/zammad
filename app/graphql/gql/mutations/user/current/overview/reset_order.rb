# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::Overview::ResetOrder < BaseMutation
    description 'Reset the overview sorting for the current user'

    field :success, Boolean, null: false, description: 'Was the reset successful?'
    field :overviews, [Gql::Types::OverviewType], null: true, description: 'List of overview sortings for the user'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.overview_sorting')
    end

    def resolve
      ActiveRecord::Base.transaction do
        ::User::OverviewSorting.where(user: context.current_user).destroy_all
      end

      Gql::Subscriptions::User::Current::OverviewOrderingUpdates
        .trigger_by(context.current_user)

      {
        success:   true,
        overviews: Service::User::Overview::List.new(context.current_user).execute
      }
    end
  end
end
