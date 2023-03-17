# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Concerns::HasDefaultModelRelations
  extend ActiveSupport::Concern

  included do
    belongs_to :created_by, Gql::Types::UserType, null: false, description: 'User that created this record'
    belongs_to :updated_by, Gql::Types::UserType, null: false, description: 'Last user that updated this record'
  end
end
