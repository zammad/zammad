# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

# Provide the internal id only for objects that need it, for example
#   in URLs.
module Gql::Concerns::HasInternalNoteField
  extend ActiveSupport::Concern

  included do
    # internal note field
    field :note, String, null: true, authorize: ['ticket.agent', 'admin.*'], description: 'Internal note'
  end
end
