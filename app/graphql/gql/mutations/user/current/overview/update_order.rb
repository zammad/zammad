# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::Overview::UpdateOrder < BaseMutation
    description 'Update the overview sorting for the current user'

    argument :overview_ids, [GraphQL::Types::ID], description: 'The ordered list of overviews' # , loads: Gql::Types::OverviewType

    field :success, Boolean, null: false, description: 'Was the reset successful?'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.overview_sorting')
    end

    def resolve(overview_ids:)
      Service::User::Overview::UpdateOrder
        .new(context.current_user, authorized_overviews(overview_ids))
        .execute

      Gql::Subscriptions::User::Current::OverviewOrderingUpdates
        .trigger_by(context.current_user)

      { success: true }
    end

    private

    def authorized_overviews(overview_ids)
      overview_ids
        .filter_map { |elem| load(elem) }

    end

    def load(gql_id)
      Gql::ZammadSchema
        .authorized_object_from_id(gql_id, type: Overview, user: context.current_user, query: :use?)
    rescue Exceptions::Forbidden
      nil
    end
  end
end
