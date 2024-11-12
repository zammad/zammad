# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class ExternalReferencesInputType < BaseInputType
    description 'Represents the ticket external links to be added'

    argument :github,
             [Gql::Types::UriHttpStringType],
             required:    false,
             description: 'Links for the github integration'

    argument :gitlab,
             [Gql::Types::UriHttpStringType],
             required:    false,
             description: 'Links for the gitlab integration'

    argument :idoit,
             [Integer],
             required:    false,
             description: 'Object ids for the Idoit integration'
  end
end
