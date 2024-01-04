# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Concerns::HasScopedModelUserRelations
  extend ActiveSupport::Concern

  included do
    scoped_fields do
      belongs_to :created_by, Gql::Types::UserType, description: 'User that created this record'
      belongs_to :updated_by, Gql::Types::UserType, description: 'Last user that updated this record'
    end
  end
end
