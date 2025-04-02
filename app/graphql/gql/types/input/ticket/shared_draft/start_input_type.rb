# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class Ticket::SharedDraft::StartInputType < Gql::Types::BaseInputObject
    description 'The ticket start draft fields'

    argument :form_id, String, description: 'Form ID to copy attachments from'
    argument :content, GraphQL::Types::JSON, description: 'Content of the draft'
    argument :group_id, GraphQL::Types::ID,
             loads:       Gql::Types::GroupType,
             description: 'Group to put shared draft into'
  end
end
