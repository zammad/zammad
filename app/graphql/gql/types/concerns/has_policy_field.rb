# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Concerns::HasPolicyField
  extend ActiveSupport::Concern

  included do
    field :policy, Gql::Types::PolicyType, null: false, method: :itself, description: 'Pundit policy queries for the current object and user.'
  end
end
