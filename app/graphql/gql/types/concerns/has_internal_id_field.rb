# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Provide the internal id only for objects that need it, for example
#   in URLs.
module Gql::Types::Concerns::HasInternalIdField
  extend ActiveSupport::Concern

  included do
    field :internal_id, Integer, null: false, description: 'Internal database ID'
    def internal_id
      object.id
    end
  end

end
