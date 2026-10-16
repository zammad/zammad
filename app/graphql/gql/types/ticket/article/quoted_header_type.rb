# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Ticket::Article::QuotedHeaderType < Gql::Types::BaseObject
    description 'Header lines of an article to quote when forwarding or replying to it, following the configured email sender format'

    field :from, String, description: "'From' information of the original email to be inserted in the quoted email block"
    field :to, String, description: "'To' information of the original email to be inserted in the quoted email block"
    field :cc, String, description: "'Cc' information of the original email to be inserted in the quoted email block"
    field :author_name, String, description: "Author name for the reply citation ('On ..., X wrote:')"
  end
end
