# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Provide the internal id only for objects that need it, for example
#   in URLs.
module Gql::Types::Concerns::HasInternalNoteField
  extend ActiveSupport::Concern

  included do
    internal_fields do
      field :note, String, description: 'Internal note'
    end
  end
end
