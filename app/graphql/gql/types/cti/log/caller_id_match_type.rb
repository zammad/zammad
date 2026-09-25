# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Cti::Log::CallerIdMatchType < Gql::Types::BaseObject
    description 'A caller ID matched to one side of a call, either a known or a possible user'

    field :level, String, null: false, description: "Match quality, 'known' or 'maybe'"
    field :comment, String, null: true
    # Dependent like a belongs_to, so a phone agent without ticket permissions sees the matched user's name.
    field :user, Gql::Types::UserType, null: true, is_dependent_field: true

    # The match is a plain hash from Cti::Log#preferences, so the belongs_to macro
    #   cannot resolve it; use its batch loader directly.
    def user
      return nil if object[:user_id].blank?

      Gql::RecordLoader.for(::User).load(object[:user_id])
    end
  end
end
