# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::Overview::UpdateLastUsed < BaseMutation
    description 'Update the last used information of the current user in their user preferences'

    argument :overviews_last_used, [Gql::Types::Input::User::Current::OverviewLastUsedType], description: 'List of overviews and their last used info'

    field :success, Boolean, null: false, description: 'Was the save successful?'

    def resolve(overviews_last_used:)
      value_to_store = overviews_last_used.each_with_object({}) do |olu, value|
        value[olu.overview.id.to_s] = olu.last_used_at
      end

      context.current_user.preferences[:overviews_last_used] = value_to_store
      context.current_user.save!

      { success: true }
    end
  end
end
