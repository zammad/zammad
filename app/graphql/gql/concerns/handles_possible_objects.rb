# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Concerns::HandlesPossibleObjects
  extend ActiveSupport::Concern

  included do
    private

    def fetch_object(object_id, permission: :show?)
      Gql::ZammadSchema
        .authorized_object_from_id(
          object_id,
          user:  context.current_user,
          query: permission,
          type:  self.class.possible_objects
        )
    end
  end

  class_methods do
    def possible_objects(*list)
      if list.present?
        @possible_objects = list.to_a
      elsif defined?(@possible_objects)
        @possible_objects
      else
        @possible_objects = []
      end
    end
  end

end
