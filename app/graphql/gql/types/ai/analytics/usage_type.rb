# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AI::Analytics
  class UsageType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalIdField

    description 'AI::Analytics::Usage records a usage of an AI result that can be used for analytics purposes.'

    field :user_has_provided_feedback, Boolean, description: 'Indicates if the user has already provided feedback for this AI result.'
  end

  def user_has_provided_feedback
    !object.rating.nil?
  end
end
